module spi_master_sv (
    input  logic        clk,
    input  logic        rst_n,

    // Control interface
    input  logic        start,
    output logic        done,

    input  logic [15:0] clk_div,
    input  logic        cpol,
    input  logic        cpha,

    input  logic [7:0]  tx_data,
    output logic [7:0]  rx_data,

    // SPI signals
    output logic        MOSI,sclk,cs_n,
    input  logic        MISO
);


    // ---------------------------------------------------------
    // SCLK generator
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk <= cpol;  // idle
        else
            sclk <= ~sclk; 
    end

    // ---------------------------------------------------------
    // FSM
    // ---------------------------------------------------------
    typedef enum logic [1:0] {IDLE, LOAD, TRANSFER, DONE} state_t;
    state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ---------------------------------------------------------
    // Shift registers & counters
    // ---------------------------------------------------------
    logic [7:0] tx_shift;
    logic [3:0] bit_cnt;

    always_comb begin
        next_state = state;

        case (state)
            IDLE:     if (start) next_state = TRANSFER;
            TRANSFER: if ((bit_cnt == 8) && ((!sclk) == (cpol ^ cpha))) next_state = IDLE;
        endcase
    end


    logic shift_edge;

    //(cpol ^ cpha) = 0 [shift on falling edge]
    //(cpol ^ cpha) = 1 [shift on Rising  edge]

    //if sclk = 0 [next edge will be a rising edge]
    
    assign shift_edge = ~(sclk == (cpol ^ cpha));
    // ---------------------------------------------------------
    // Data-path logic
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs_n    <= 1'b1;
            done    <= 0;
            MOSI    <= 0;
            rx_data <= 0;
            bit_cnt <= 0;
        end else begin
            case (state)

                IDLE: begin
                    done <= 0;
                    cs_n <= 1;

                    if(start) begin
                        cs_n        <= 0;
                        tx_shift    <= tx_data;
                        bit_cnt     <= 0;
                    end
                end

                TRANSFER: begin
                    if(bit_cnt < 8) begin
                        // Shift Edge
                        if (shift_edge) begin
                            MOSI     <= tx_shift[7];            //generating MOSI from tx_shift
                            tx_shift <= {tx_shift[6:0], 1'b0};  //shifting by one bit
                            bit_cnt  <= bit_cnt + 1;            //incrementing bit counter
                        end else begin // Sample Edge
                            rx_data <= {rx_data[6:0], MISO};  //Storing MISO into rx_data
                        end
                    end else begin
                        if (!shift_edge) begin
                            rx_data     <= {rx_data[6:0], MISO};  //Storing last MISO bit into rx_data
                            done        <= 1;
                        end else begin 
                            done        <= 0;
                            cs_n        <= 1;
                            bit_cnt     <= 0;
                            rx_data     <= 0;
                        end
                    end
                end

            endcase
        end
    end

endmodule
