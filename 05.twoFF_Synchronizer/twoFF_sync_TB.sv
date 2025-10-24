`timescale 1ns/1ns

module twoFF_sync_tb ();
    
    logic [5:0] TB_inD;
    logic [5:0] TB_outD;
    logic TB_clk, TB_rst_n;

    twoFF_sync dut(
        .inD(TB_inD),
        .outD(TB_outD),
        .clk(TB_clk),
        .rst_n(TB_rst_n)
    );

    initial begin
        TB_rst_n = 0;
        TB_inD = 6'b0;
        TB_clk = 0;

        #6;
        TB_rst_n = 1;
        TB_inD = 6'b110011;
    end
    
    always #5 TB_clk = ~TB_clk;

endmodule
