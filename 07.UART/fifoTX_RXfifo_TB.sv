
`timescale 1ns/1ns

module fifoTx_Rxfifo_TB();

logic [7:0] Transmitted_data;

logic clk, tx_clk, rx_clk;
logic rst_n;
logic tx_rx_line;

logic txfifo_wrEN, txfifo_rdEN, txfifo_Dvalid;
logic txfifo_full, txfifo_empty;
logic [7:0] txfifo_Din, txfifo_Dout;

logic rxfifo_wrEN, rxfifo_rdEN, rxfifo_Dvalid;
logic rxfifo_full, rxfifo_empty;
logic [7:0] rxfifo_Din, rxfifo_Dout;

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


transmitter tx (
    .tx_clk(tx_clk),
    .rst_n(rst_n),
    .Din_valid(txfifo_Dvalid),
    .data_in(txfifo_Dout),
    .rd_EN(txfifo_rdEN),
    .tx(tx_rx_line)
);

receiver rx (
    .rx_clk(rx_clk),
    .rst_n(rst_n),
    .rx(tx_rx_line),
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

initial begin
    rst_n = 0;
    clk = 0;
    txfifo_Din = 0;
    txfifo_wrEN = 0;
    rxfifo_rdEN = 1;

    Transmitted_data = 8'b11010011;

    #20;
    txfifo_Din = Transmitted_data;
    txfifo_wrEN = 1;
    rst_n = 1;
    
    #10;
    txfifo_Din = 8'b0;
    txfifo_wrEN = 0;

    @(posedge rxfifo_Dvalid);
    if(rxfifo_Dout === Transmitted_data) $display("Data transmitted tx:%b | Data received rx:%b ", Transmitted_data, rxfifo_Dout);
    else $display("data mismatch tx:%b | rx:%b ", Transmitted_data, rxfifo_Dout);
end

always #5 clk = ~clk;

endmodule