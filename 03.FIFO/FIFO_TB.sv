
`timescale 1ns/1ns

module fifo_TB();

    //outputs from the TB
    logic TB_clk, TB_rst_n, TB_r_EN, TB_w_EN;
    logic [7:0] TB_data_in;

    //inputs to the TB
    logic TB_full, TB_empty;
    logic [7:0] TB_data_out;

fifo dut(
    .clk(TB_clk),
    .rst_n(TB_rst_n),
    .r_EN(TB_r_EN),
    .w_EN(TB_w_EN),
    .data_in(TB_data_in),
    .full(TB_full),
    .empty(TB_empty),
    .data_out(TB_data_out)
);

initial begin
    TB_clk = 0;
    TB_r_EN = 0;
    TB_w_EN = 0;
    TB_data_in = 8'b0;
    TB_rst_n = 0;
    
    #6;

    TB_rst_n = 1;
    TB_w_EN = 1;

    TB_data_in = 1;
    #10;
    TB_data_in = 2;
    #10;
    TB_r_EN = 1;
    TB_data_in = 3;
    #10;
    TB_data_in = 4;
    #10;

    TB_data_in = 8'b0;
    TB_w_EN = 0;

end

always #5 TB_clk = ~TB_clk;

endmodule