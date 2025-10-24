
module UART_top(

input logic clk,rst_n,
output logic tx,
input logic rx,

output logic txfifo_full,
input logic txfifo_wrEN,
input logic [7:0] txfifo_Din,

output logic rxfifo_empty,
output logic [7:0] rxfifo_Dout,
output logic rxfifo_Dvalid,
input logic rxfifo_rdEN

);

logic tx_clk, rx_clk;

logic txfifo_empty;
logic txfifo_Dout;
logic txfifo_Dvalid;
logic txfifo_rdEN;

logic rxfifo_wrEN;
logic rxfifo_full;
logic [7:0] rxfifo_Din;

baudGen clk_gen (
    .clk(clk),
    .rst_n(rst_n),
    .tx_clk(tx_clk),
    .rx_clk(rx_clk)
);

Asyc_FIFO tx_fifo(
    .rst_n(rst_n),
    .data_in(txfifo_Din),
    .wr_clk(clk),
    .wr_EN(txfifo_wrEN),
    .data_out(txfifo_Dout),
    .rd_clk(tx_clk),
    .rd_EN(txfifo_rdEN),
    .Dout_valid(txfifo_Dvalid),
    .full(txfifo_full),
    .empty(txfifo_empty)
);


transmitter tx_ (
    .tx_clk(tx_clk),
    .rst_n(rst_n),
    .Din_valid(txfifo_Dvalid),
    .data_in(txfifo_Dout),
    .rd_EN(txfifo_rdEN),
    .tx(tx)
);

receiver rx_ (
    .rx_clk(rx_clk),
    .rst_n(rst_n),
    .rx(rx),
    .dataout(rxfifo_Din),
    .wr_EN(rxfifo_wrEN)
);

Asyc_FIFO rx_fifo(
    .rst_n(rst_n),
    .data_in(rxfifo_Din),
    .wr_clk(rx_clk),
    .wr_EN(rxfifo_wrEN),
    .data_out(rxfifo_Dout),
    .rd_clk(clk),
    .rd_EN(rxfifo_rdEN),
    .Dout_valid(rxfifo_Dvalid),
    .full(rxfifo_full),
    .empty(rxfifo_empty)
);

endmodule