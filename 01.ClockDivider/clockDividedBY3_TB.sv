
`timescale 1ns/1ns

module clockDividedBY3_TB();

    logic inputclk, CLKD3, reset;

    ClockDividerBY3_2 dut(
        .clk(inputclk),
        .clkD3(CLKD3),
        .rst(reset)
    ); 

    initial begin
        inputclk = 0;

        reset = 1; #10
        reset = 0;
    end

    always begin
        inputclk <= ~inputclk; #10;
    end
endmodule