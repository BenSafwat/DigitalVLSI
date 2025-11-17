`timescale 1ns/1ns

module tb_spi;

    // Clock
    bit clk;
    logic rst_n;

    // Master signals
    logic start;
    logic done_m;
    logic [7:0] tx_data_m, rx_data_m;
    logic [15:0] clk_div;
    logic cpol;
    logic cpha;

    logic MOSI, MISO, sclk, cs_n;

    // Slave signals
    logic [7:0] rx_data_s, tx_data_s;
    logic done_s;

    // ---------------------------------------------------------
    // Clock generation
    // ---------------------------------------------------------
    always #5 clk = ~clk;  // 100 MHz system clock

    // ---------------------------------------------------------
    // Instantiate SPI Master
    // ---------------------------------------------------------
    spi_master_sv master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done_m),
        .clk_div(clk_div),
        .cpol(cpol),
        .cpha(cpha),
        .tx_data(tx_data_m),
        .rx_data(rx_data_m),
        .MOSI(MOSI),
        .sclk(sclk),
        .cs_n(cs_n),
        .MISO(MISO)
    );

    // ---------------------------------------------------------
    // Instantiate SPI Slave
    // ---------------------------------------------------------
    spi_slave_minimal_cpol_cpha slave (
        .sclk(sclk),
        .cs_n(cs_n),
        .MOSI(MOSI),
        .MISO(MISO),
        .tx_data(tx_data_s),       // example slave data
        .rx_data(rx_data_s),
        .cpol(cpol),
        .cpha(~cpha),
        .done(done_s)
    );

    // ---------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------
    initial begin
        rst_n = 0;
        start = 0;
        clk_div = 0;   // small divider for simulation
        cpol = 0;   //Idle at 0
        cpha = 0;   

        tx_data_m = 8'b1001_1001;   //99
        tx_data_s = 8'b1010_0101;   //A5

        #20;
        rst_n = 1;
        #20;

        // Start transaction
        start = 1;
        #10;
        start = 0;

        @(posedge done_s)
        // Display results
        $display("Master sent: %0h, received: %0h", tx_data_m, rx_data_m);
        $display("Slave received: %0h, sending: %0h", rx_data_s,tx_data_s);

        //$stop;
    end

endmodule
