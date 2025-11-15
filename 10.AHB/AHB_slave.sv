
import AHB_defs::*;

module AHB_slave (
    input logic H_CLK,
    input logic H_RESETn,
    input logic H_SEL,
    
    output logic [31:0] H_RDATA,
    output logic H_RESPONSE,
    output logic H_READY_OUT,

    input logic [31:0] H_ADDR,
    input logic [31:0] H_WDATA,
    input H_SIZE_t H_SIZE,
    input H_BURST_t H_BURST,
    input logic [3:0] H_PROTECT,
    input H_TRANS_t H_TRANS,
    input logic H_WRITE,
    input logic H_MASTLOCK,
    input logic H_READY_IN
);

    // ------------------------------------------------------------
    // Memory definition
    // ------------------------------------------------------------
    /*256 x 32-bit memory
    advanced road is to make a separet memory module
    and use the AHB_slave as interface only
    */
    logic [31:0] mem [0:255];
    localparam int LATENCY = 0; // simulates latency of the memory

    /*AHB bus, by default, assumes that
    every address position contains a byte(8-bits) of data,
    so if your memory contain words(32-bits) in each address position then,
    you should access mem[0] when H_ADDR = 0,1,2,3
    bec, byte 0,1,2,3 are all in the first memory location mem[0]
    we can do this by "aligning" the AHB address to our memory address
    this can be done in our case by shifting right twice (>>2)
    or Ignoring the first two bits [0],[1]
    */

    // ------------------------------------------------------------
    // State encoding
    // ------------------------------------------------------------
    typedef enum logic [1:0] {
        S_IDLE,        // Waiting for valid 
        S_WAIT,
        S_ACCEPT_RESPOND      // Sending response to master
    } slave_state_t;


    slave_state_t current_state, next_state;

    // ------------------------------------------------------------
    // Sequential: state update (synchronous with HCLK)
    // ------------------------------------------------------------
    always_ff @(posedge H_CLK or negedge H_RESETn) begin
        if (!H_RESETn)
            //current_state <= S_IDLE;
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end



    logic [1:0] wait_cntr;
    always_comb begin
        next_state = current_state;
        H_READY_OUT = 1;   // default

        case (current_state)

            S_IDLE:begin
                H_READY_OUT = 1;
                if (H_SEL && H_READY_IN && (H_TRANS == NONSEQ || H_TRANS == SEQ)) begin
                    if (LATENCY == 0) begin
                        next_state = S_ACCEPT_RESPOND;
                    end else begin
                        next_state = S_WAIT;
                    end
                end
            end

            S_WAIT:begin
                H_READY_OUT = 0;
                if(wait_cntr + 1 >= LATENCY)
                    next_state = S_ACCEPT_RESPOND;
            end
            
            S_ACCEPT_RESPOND:begin
                H_READY_OUT = 1;
                if (H_SEL && H_READY_IN && (H_TRANS == NONSEQ || H_TRANS == SEQ)) begin
                    if (LATENCY == 0) begin
                        next_state = current_state;
                    end else begin
                        next_state = S_WAIT;
                    end
                end else next_state = S_IDLE;

            end
            
        endcase
    end

    //local registers
    logic [31:0] wADDR_reg, rADDR_reg;
    H_SIZE_t SIZE_reg;
    logic WRITE_reg;


    //check if the address is within range
    logic addr_valid;
    assign addr_valid = (H_ADDR[9:2] <= 255);  // 256 words

    logic [3:0] inc_amount;
    always_comb begin
        case(SIZE_reg)
            BYTE:      inc_amount = 1;
            HALFWORD:  inc_amount = 2;
            WORD:      inc_amount = 4;
            default:   inc_amount = 4;
        endcase
    end

    always_ff @(posedge H_CLK or negedge H_RESETn) begin
        if(!H_RESETn)begin
            wait_cntr   <= 0;
            wADDR_reg    <= 0;
            WRITE_reg   <= 0;
            SIZE_reg    <= WORD;
            
            H_RDATA <= 32'b0;       //clear output data
            H_RESPONSE <= 1'b0;     //transfer status is OKAY
        end else begin
            case(current_state)

                S_IDLE: begin
                    
                    if(H_SEL && H_READY_IN && H_TRANS != IDLE && H_TRANS != BUSY)begin
                        wADDR_reg    <= H_ADDR;
                        WRITE_reg   <= H_WRITE;
                        SIZE_reg    <= H_SIZE;
                    end

                    H_RESPONSE <= 1'b0;
                end
                
                S_WAIT:begin
                    // This simulates the memory taking time to write/read
                    // if it was external memory, then here
                    // you will have to check if memory has finished its operation
                    wait_cntr <= wait_cntr + 1;
                end

                S_ACCEPT_RESPOND:begin
                    //rest the wait counter
                    wait_cntr <= 0;
                    
                    //#################################################
                    //######  Storing and Incrementing the Address  ###
                    //#################################################
                    if (H_TRANS == NONSEQ) begin
                        //for the first NONSEQ just save the address
                        wADDR_reg    <= H_ADDR;
                        WRITE_reg   <= H_WRITE;
                        SIZE_reg    <= H_SIZE;

                        if(H_BURST != SINGLE) rADDR_reg <= H_ADDR + inc_amount;
                        else rADDR_reg <= H_ADDR;    //you don't actually use it because you use H_ADDR it self

                        H_RESPONSE <= 1'b0;
                    end else if (H_TRANS == SEQ) begin
                        // SEQ mean you are in a burst
                        if(WRITE_reg) wADDR_reg <= wADDR_reg + inc_amount; // INCR and INCR4/8/16
                        if(!H_WRITE) rADDR_reg <= rADDR_reg + inc_amount;

                    end else begin
                        //This brach shouldn't be reachable for now
                        //IDLE & BUSY Ignor the incoming address
                        //Implementing BUSY next
                        wADDR_reg <= wADDR_reg; 
                    end

                    //#####################################################
                    //##########  Actual Write and read operation  ########
                    //#####################################################
                    if(addr_valid) begin
                        if(WRITE_reg)begin
                            //write the data coming from the master to slave
                            //address from cycle:1 and data from current cycle
                            case(SIZE_reg)
                                BYTE: begin
                                    case (wADDR_reg[1:0])
                                        2'b00: mem[wADDR_reg[9:2]][7:0]   <= H_WDATA[7:0];
                                        2'b01: mem[wADDR_reg[9:2]][15:8]  <= H_WDATA[7:0];
                                        2'b10: mem[wADDR_reg[9:2]][23:16] <= H_WDATA[7:0];
                                        2'b11: mem[wADDR_reg[9:2]][31:24] <= H_WDATA[7:0];
                                        default: mem[wADDR_reg[9:2]][7:0]   <= H_WDATA[7:0];
                                    endcase
                                end

                                HALFWORD: begin
                                    case (wADDR_reg[1:0])
                                        2'b00: mem[wADDR_reg[9:2]][15:0]  <= H_WDATA[15:0];
                                        2'b10: mem[wADDR_reg[9:2]][31:16] <= H_WDATA[15:0];
                                        default: mem[wADDR_reg[9:2]][15:0]  <= H_WDATA[15:0];
                                    endcase
                                end

                                WORD : mem[wADDR_reg[9:2]] <= H_WDATA;
                                default: mem[wADDR_reg[9:2]] <= H_WDATA;
                            endcase
                        end 
                        
                        if ((!H_WRITE) && (H_TRANS == NONSEQ))begin
                            //read the data from the specified address in the memory and send it to the Master
                            H_RDATA <= mem[H_ADDR[9:2]];
                        end else if ((!H_WRITE) && (H_TRANS == SEQ)) begin
                            H_RDATA <= mem[rADDR_reg[9:2]];
                        end

                        H_RESPONSE <= 1'b0;     //Address is OKAY
                    end else begin
                        H_RESPONSE <= 1'b1;     //Address has ERROR
                    end  
                end

                default:;
            endcase

        end
    end

endmodule
