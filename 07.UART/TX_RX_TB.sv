
`timescale 1ns/1ns

module Tx_Rx_TB();

logic clk, tx_clk, rx_clk;
logic rst_n;
logic tx_rx_line;

logic rd_EN, wr_EN, D_valid;
logic [7:0] tx_data, rx_data;


transmitter tx (
    .tx_clk(tx_clk),
    .rst_n(rst_n),
    .Din_valid(D_valid),
    .data_in(tx_data),
    .rd_EN(rd_EN),
    .tx(tx_rx_line)
);

receiver rx (
    .rx_clk(rx_clk),
    .rst_n(rst_n),
    .rx(tx_rx_line),
    .dataout(rx_data),
    .wr_EN(wr_EN)
);

baudGen clk_gen (
    .clk(clk),
    .rst_n(rst_n),
    .tx_clk(tx_clk),
    .rx_clk(rx_clk)
);

initial begin
    rst_n = 0;
    clk = 0;
    D_valid = 0;
    tx_data = 0;

    #22;
    tx_data = 8'b11010011;
    D_valid = 1;
    rst_n = 1;

    @(posedge wr_EN);
    if(rx_data === tx_data) $display("Data transmitted tx:%b | Data received rx:%b ", tx_data, rx_data);
    else $display("data mismatch tx:%b | rx:%b ", tx_data, rx_data);
end

always #5 clk = ~clk;

endmodule