
module i2c_master_v2 (
    input logic clk, rst_n,
    input logic En_i2c,
    input logic [7:0] din,
    input logic [2:0] dvsr,
    input logic Write,

    output logic [7:0] dout,
    output logic ack, ready, doneTick,

    inout tri SDA,
    inout tri SCL
);
    // ------------------------------------------------------
    // Define Machine states
    // ------------------------------------------------------
    typedef enum logic [2:0] {
        IDLE,
        START0,START,
        LOAD,
        SHIFT,
        STOP
    }STATE;

    STATE current_state, next_state;

    // ------------------------------------------------------
    // i2c_clk generation
    // ------------------------------------------------------
    // assuming: 100MHz system clk
    // and SCL = 100KHz (Standard Frequency)
    // then i2c_clk should be 4xSCL = 400KHz
    // then divisor = 100MHz/400KHz = 250
    logic [6:0] i2cClk_counter;
    logic i2c_clk;
    always_ff @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            i2c_clk <= 1'b0;
            i2cClk_counter <= 1'b0;
        end else if (i2cClk_counter == 124)begin
            i2c_clk <= ~i2c_clk;
            i2cClk_counter <= 1'b0;
        end else begin
            i2cClk_counter <= i2cClk_counter + 1;
        end
    end
    
    // ------------------------------------------------------
    // Generating SCL
    // ------------------------------------------------------
    logic [1:0] SCL_counter;
    logic SCL_in = 1'b1;
    always_ff @(posedge i2c_clk or negedge rst_n)begin
        if(!rst_n)begin
            SCL_in <= 1'b1;
            SCL_counter <= 1'b0;
        end else begin
            if(current_state == IDLE) SCL_in = 1;
            else if(current_state == LOAD) SCL_in = 0;
            else begin
                if(SCL_counter == 1)begin
                    SCL_in <= ~SCL_in;
                    SCL_counter <= 1'b0;
                end else begin
                    SCL_counter <= SCL_counter + 1;
                end
            end
        end 
    end 
    
    //converts from logic 1/0 to z/0 which is crucial for open-drain bus
    assign SCL = SCL_in? 1'bz : 1'b0;


    // ------------------------------------------------------
    // STATE resgister
    // ------------------------------------------------------
    always_ff @(posedge i2c_clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // ------------------------------------------------------
    // next STATE logic
    // ------------------------------------------------------
    logic [3:0] bit_count; //max is 16
    logic SDA_in;
    logic [8:0] tx, rx;

    always_comb begin
        next_state = current_state;

        case(current_state)
        
            IDLE:begin
                if(En_i2c) next_state = START0;
            end
            
            //Start Condition
            START0:begin
                if(~SCL_in && (SCL_counter == 1))
                    next_state = START;
            end
            START:begin
                if(SCL_in && (SCL_counter == 1))
                    next_state = LOAD;
            end
            
            LOAD:begin
                next_state = SHIFT;
            end 
                       
            SHIFT:begin
                if (bit_count > 9)begin
                    if(En_i2c) next_state = LOAD;
                    else next_state = STOP;
                end 
            end

            //Stop Condition
            STOP:begin
                next_state = IDLE;
            end
 
            default: next_state = IDLE;
        endcase
    end


    // ------------------------------------------------------
    // STATE operation
    // ------------------------------------------------------
    always_ff @(posedge i2c_clk or negedge rst_n)begin
        if(!rst_n)begin
            doneTick <= 1'b0;
            ready <= 1'b1;
            
            tx <= 1'b0;
            bit_count <= 1'b0;    //reset transferred bit count
            SDA_in <= 1'b1;       // SDA released (idle high)

            ack <= 1'b0;
            dout <= 1'b0;
        end else begin
            case(current_state)
                IDLE:begin
                    //reset flags
                    ack <= 1'b0;
                    ready <= 1'b1;
                    doneTick <= 1'b0;

                    bit_count <= 1'b0;    //reset transferred bit count

                    //keep the bus released as long as you are IDLE
                    SDA_in <= 1'b1;

                end
                
                //START0: Nothing
                START:begin
                    SDA_in <= 1'b0;     //start codition
                    
                    ack <= 1'b0;
                    ready <= 1'b0;
                    doneTick <= 1'b0;
                end

                LOAD:begin
                    tx[8:0] <= {din[7:0],1'b1}; //load the data to tx
                    bit_count <= 0;
                    
                    ack <= 1'b0;
                    ready <= 1'b0;
                    doneTick <= 1'b0;
                end 
                           
                STOP:begin
                    SDA_in <= 1'b1;             //Stop condition
                    
                    ack <= 1'b0;
                    ready <= 1'b1;
                    doneTick <= 1'b0;
                end

                SHIFT:begin
                    if(~SCL_in && (SCL_counter == 0))begin 
                        
                        //ready <= 1'b0;       //deassert ready which means the device is busy
                        //doneTick <= 1'b0;

                        //WRITE to the slave
                        if(bit_count < 9)begin
                            if(Write)begin
                                //generate SDA according to tx MSB content then shift left 1 bit,
                                //note tx[0]=1 to release the bus to recieve the ack from the slave
                                SDA_in <= tx[8];
                                tx <= tx << 1;
                            end else if (~Write) begin
                                if(bit_count == 8) SDA_in <= 0; //at the 9th bit pull SDA low to send ack to the slave
                                else SDA_in <= 1;               //this makes SDA by default = z so it can be controled by the slave to recieve the data
                            end
                        end else if(bit_count == 9) begin
                            SDA_in <= 1'b0;     //Desserting SDA so it can be released in the stop condition
                            
                            dout <= rx[8:1];    //export rx contents to dout

                            //when transmitte/receive is done, output r[0](ack-bit) to ack
                            //if success rx[0] should be 0, so we invert it to get 1 on the ack
                            //if ack is 0 then rx[0] is 1, which means faild acknowledgment 
                            ack <= ~rx[0];
                            ready <= 1'b1;      //assert ready means the device is ready for the next word
                            doneTick <= 1'b1;   //finished the current transfer
                        end

                        bit_count <= bit_count + 1;
                    end
                end
            endcase
        end
    end

    always @(posedge SCL_in or negedge rst_n)begin
        if (!rst_n)begin
            rx <= 1'b0;
        end else begin
            case(current_state)
                SHIFT:begin
                    rx <= {rx[7:0], SDA};
                end
            endcase  
        end 
    end 
            
     

    assign SDA = SDA_in? 1'bz : 1'b0;

endmodule