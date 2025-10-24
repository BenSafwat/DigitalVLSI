module clkMux_1FF (
    input logic sel, clk1, clk2, rst_n,
    output logic clk_out
);
    logic en_clk1, en_clk2;
    logic clk1_out, clk2_out;
    logic q1, q2;

    always_comb begin
        en_clk1 = ~sel & ~q2;
        en_clk2 = sel & ~q1;

        clk1_out = clk1 & q1;
        clk2_out = clk2 & q2;

        clk_out = clk1_out | clk2_out;
    end

    always_ff @(posedge clk1)begin
        if(!rst_n)  q1 <= 0;
        else        q1 <= en_clk1;
    end

    always_ff @(posedge clk2) begin
        if(!rst_n)  q2 <= 0;
        else        q2 <= en_clk2;
    end 
endmodule