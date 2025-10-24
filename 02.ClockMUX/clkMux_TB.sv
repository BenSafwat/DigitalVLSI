`timescale 1ns/1ns

module clkMux_TB;

    logic tb_sel, tb_clk1, tb_clk2, tb_rst;     //output from the TB
    logic tb_clk_1FF;                           //Input to the TB
    logic tb_clk_2FF;                           //Input to the TB

    clkMux_2FF dut_2ff (
        .sel(tb_sel),
        .clk1(tb_clk1),
        .clk2(tb_clk2),
        .rst_n(tb_rst),
        .clk_out(tb_clk_2FF)
    ); 

    clkMux_1FF dut_1ff (
        .sel(tb_sel),
        .clk1(tb_clk1),
        .clk2(tb_clk2),
        .rst_n(tb_rst),
        .clk_out(tb_clk_1FF)
    ); 

    initial begin
        tb_rst = 0;
        tb_sel = 0;
        tb_clk1 = 0;
        tb_clk2 = 0;

        #6;
        tb_rst = 1; //since sel=0 initially output will be clk1

        #45;        //wait for 4 cycles from clk1
        tb_sel = 1; //should output clk2

    end

    always #5   tb_clk1 <= ~tb_clk1; 
    always #10  tb_clk2 <= ~tb_clk2;

endmodule