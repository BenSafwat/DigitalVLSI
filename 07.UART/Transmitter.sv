module transmitter (
    input logic tx_clk, rst_n, Din_valid,
    input logic [7:0] data_in,
    output logic rd_EN, tx 
);
    typedef enum logic [1:0] {idle, read, transmit} state;

    state current_state, next_state;

    logic [9:0] tx_frame;
    logic [4:0] bit_counter;

    //updating the current state with the positive edge
    always_ff @(posedge tx_clk, negedge rst_n)begin
        if(!rst_n)
            current_state <= idle;
        else
            current_state <= next_state;
    end

    //calculating the next state using combinational logic
    always_comb begin
        case(current_state)
            idle: begin
                if(Din_valid) next_state = read;
                else next_state = current_state;
            end

            read: next_state = transmit;

            transmit:begin 
                if (bit_counter>9)begin
                    if (Din_valid) next_state = read;
                    else next_state = idle;
                end else next_state = current_state;
            end

            default: next_state = idle;
        endcase
    end

    //actual trasmition
    always_ff @(posedge tx_clk, negedge rst_n ) begin
        if (!rst_n)begin
            tx_frame <= 10'b0;
            tx <= 1;                //transition tx to idle_line
            bit_counter <= 5'b0;    //rest the counter
            rd_EN <= 0;            //tell the FIFO I am ready!!
        end else begin
            case (current_state)
                idle: begin
                    tx_frame <= 10'b0;
                    tx <= 1;                //transition tx to idle_line
                    bit_counter <= 5'b0;    //rest the counter
                    rd_EN <= 1;            //tell the FIFO I am ready!!
                end

                read: begin
                    tx_frame <= {1'b1, data_in[7:0], 1'b0}; //construct the frame to send [stop_Bit + data + start_Bit]
                    bit_counter <= 5'b0;
                    rd_EN <= 0;
                end 

                transmit:begin
                    if (bit_counter <= 9) begin
                        tx <= tx_frame[0];
                        tx_frame <= tx_frame >> 1;
                        bit_counter <= bit_counter + 1;
                    end else begin
                        rd_EN <= 1;
                        tx <= 1;
                    end
                end
            endcase
        end
    end

endmodule