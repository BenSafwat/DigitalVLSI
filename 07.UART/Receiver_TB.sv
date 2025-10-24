`timescale 1ns/1ns

module receiver_tb;

    // DUT I/O
    logic rx_clk;
    logic rst_n;
    logic rx;
    logic [7:0] dataout;
    logic wr_EN;

    // Instantiate the DUT
    receiver dut (
        .rx_clk(rx_clk),
        .rst_n(rst_n),
        .rx(rx),
        .dataout(dataout),
        .wr_EN(wr_EN)
    );

    // Clock generation: 10ns period (100 MHz)
    initial rx_clk = 0;
    always #5 rx_clk = ~rx_clk;

    // Test variables
    logic [7:0] tx_data = 8'b1010_1101; // Example byte to send (0xAD)

    // UART timing
    localparam integer BIT_PERIOD = 160;  // corresponds to 16 samples per bit in receiver

    // Task to send one UART frame (start + 8 bits + stop)
    task send_uart_frame(input logic [7:0] data);
        begin
            // Start bit (low)
            rx = 0;
            #(BIT_PERIOD);

            // Send 8 data bits, LSB first
            for (int i = 0; i < 8; i++) begin
                rx = data[i];
                #(BIT_PERIOD);
            end

            // Stop bit (high)
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // Main stimulus
    initial begin
        // Initial values
        rx = 1; // idle line is high
        rst_n = 0;

        // Apply reset
        repeat (3) @(posedge rx_clk);
        rst_n = 1;
        @(posedge rx_clk);

        $display("[%0t] Starting UART RX test...", $time);

        // Send one byte
        send_uart_frame(tx_data);
        
        // Check result
        if (dataout == tx_data)
            $display("[%0t] ✅ PASS: Received = %b (0x%0h)", $time, dataout, dataout);
        else
            $display("[%0t] ❌ FAIL: Expected %b, got %b", $time, tx_data, dataout);

        // End simulation
        $display("[%0t] Simulation completed.", $time);
        //$finish;
    end

endmodule
