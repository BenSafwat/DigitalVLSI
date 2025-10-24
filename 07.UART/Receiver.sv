module receiver (
    input logic rx_clk, rst_n, rx,
    output logic [7:0] dataout,
    output logic wr_EN
);
    typedef enum logic [1:0] {IDLE, RECEIVE, WRITE} state;

    state current_state, next_state;

    logic [7:0] rx_frame;
    logic [4:0] bit_counter;

    //detecting the start bit
    logic rx_prev;  //previous rx
    logic start_bit_detected;
    always_ff @(posedge rx_clk, negedge rst_n)begin
        if(!rst_n) rx_prev <= 1;
        else rx_prev <= rx;
    end
    assign start_bit_detected = (rx_prev && !rx); 
    
    //updating the current state with the positive edge
    always_ff @(posedge rx_clk, negedge rst_n)begin
        if(!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    //calculating the next state using combinational logic
    always_comb begin
        next_state = current_state;

        case(current_state)

            IDLE:       if(start_bit_detected) next_state = RECEIVE;
            RECEIVE:    if(bit_counter == 8) next_state = WRITE; 
            WRITE:      next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end

    //############################  actual procedures  ###################
    logic [4:0]samples;

    always_ff @(posedge rx_clk, negedge rst_n)begin
        if (!rst_n)begin
            wr_EN <= 0;
            dataout <= 0;
            bit_counter <= 0;
            samples <= 0;
            rx_frame <= 0;
        end else begin
            
            case (current_state)
                IDLE:begin
                    wr_EN <= 0;
                    bit_counter <= 0;
                    samples <= 0;
                end

                RECEIVE:begin
                    if(samples < 16)begin
                        samples <= samples +1;
                    end 
                    else if (samples == 16)begin
                        rx_frame[bit_counter] <= rx;
                        samples <= 0;
                        bit_counter <= bit_counter + 1;
                    end
                    else samples <= 0;
                end
                
                WRITE:begin
                    dataout <= rx_frame;
                    wr_EN <= 1;
                end 
            endcase
        
        end
    end

endmodule