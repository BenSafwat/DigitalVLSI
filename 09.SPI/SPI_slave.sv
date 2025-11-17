module spi_slave_minimal_cpol_cpha (
    input  logic        sclk,
    input  logic        cs_n,
    input  logic        MOSI,
    output logic        MISO,

    input  logic [7:0]  tx_data,
    output logic [7:0]  rx_data,

    input  logic        cpol,
    input  logic        cpha,

    output logic done
);

    logic [7:0] tx_shift;
    logic [3:0] bit_cnt;

    logic shift_edge;

    //(cpol ^ cpha) = 0 [shift on falling edge]
    //(cpol ^ cpha) = 1 [shift on Rising  edge]

    //if sclk = 0 [next edge will be a rising edge]
    assign shift_edge = ~(sclk == (cpol ^ cpha));

    always_ff @(posedge sclk or negedge sclk or posedge cs_n) begin
        if (cs_n) begin
            bit_cnt  <= 0;
            rx_data <= 0;
            done <= 0;  
            tx_shift <= tx_data;
        end else begin
            if(bit_cnt < 8) begin

                done <= 0;

                if (shift_edge) begin
                    // Shift out
                    MISO     <= tx_shift[7];            //Genearte MISO
                    tx_shift <= {tx_shift[6:0], 1'b0};  //Shift one bit
                    bit_cnt  <= bit_cnt + 1;            //increment bit counter
                end else begin
                    // Sample MOSI
                    rx_data <= {rx_data[6:0], MOSI};  //Receive MOSI
                end
            end else begin //last bit
                if(!shift_edge) begin
                    rx_data <= {rx_data[6:0], MOSI};  //Last MOSI bit
                    done <= 1;              //flag current transaction as done
                    tx_shift <= tx_data;    //load new data
                    bit_cnt <= 0;           //reset counter
                end
            end
        end
    end


endmodule
