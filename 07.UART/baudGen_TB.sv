`timescale 1ns/1ns

module baudGen_tb();
    logic clk_tb, rst_tb;       //output from TB
    logic txclk_tb, rxclk_tb;   //input to TB
    
    baudGen dut(
        .clk(clk_tb),
        .rst_n(rst_tb),
        .tx_clk(txclk_tb),
        .rx_clk(rxclk_tb)
    );

    initial begin 
        clk_tb = 0;
        
        //System is reset
        rst_tb = 1;
        #5;
        rst_tb = 0;

        #75 rst_tb = 1;
    end 

    always #50 clk_tb = ~clk_tb;

endmodule