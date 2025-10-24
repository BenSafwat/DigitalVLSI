
`timescale 1ns/1ns
module transmitter_TB();

    logic TB_txclk, TB_rst_n, TB_Dvalid;    //output from TB
    logic [7:0] TB_data;                    //output from TB
    logic TB_txbusy, TB_tx;                 //Input to the TB

    transmitter dut (
        .tx_clk(TB_txclk),
        .rst_n(TB_rst_n),
        .Dvalid(TB_Dvalid),
        .data(TB_data),
        .txbusy(TB_txbusy),
        .tx(TB_tx)
    );

    initial begin
        TB_txclk = 0;
        TB_data = 8'b0;
        TB_Dvalid = 0;

        TB_rst_n = 0; #5;
        TB_rst_n = 1; #5;

        if(TB_txbusy == 0) begin
            
            TB_data = 8'b01010101;
            TB_Dvalid = 1;
            #20;

            TB_data = 8'b0;
            TB_Dvalid = 0;
        end
    end

    always #5 TB_txclk = ~TB_txclk; //100MHz final clock will be much slower than this 
endmodule
