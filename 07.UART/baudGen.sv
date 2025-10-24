module baudGen (
    input logic clk,rst_n,
    output logic tx_clk, rx_clk
);

    //assuming a clk of 10 MHz and baudrate of 9600
    //Then tx_clk = 10MHz/9600 = 1041 [1 cycle each 1041 clk cycle]
    //with over sampling factor of 16 then rx_clk = 10MHz/(9600*16) = 65 [1 cycle each 65 clk cycle]

    logic [11:0] tx_counter;
    logic [7:0] rx_counter;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n || (tx_counter == 1040) )
            tx_counter <= 0;
        else
            tx_counter <= tx_counter + 1'b1;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n || (rx_counter == 64) )
            rx_counter <= 0;
        else
            rx_counter <= rx_counter + 1'b1;
    end

    assign tx_clk = ~(tx_counter == 0);
    assign rx_clk = ~(rx_counter == 0);
endmodule