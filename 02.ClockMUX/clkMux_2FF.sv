module clkMux_2FF (
    input logic sel, clk1, clk2, rst_n,
    output logic clk_out
);
    logic en_clk1, en_clk2;
    logic clk1_out, clk2_out;
    logic q1, q3; //for clk1
    logic q2, q4; //for clk2

    always_comb begin
        en_clk1 = ~sel & ~q4;
        en_clk2 = sel & ~q3;

        clk1_out = clk1 & q3;
        clk2_out = clk2 & q4;

        clk_out = clk1_out | clk2_out;
    end

//clk1 branch
    always_ff @(posedge clk1)begin
        if(!rst_n)  q1 <= 0;
        else        q1 <= en_clk1;
    end

    always_ff @(negedge clk1)begin
        if(!rst_n)  q3 <= 0;
        else        q3 <= q1;
    end


//clk2 branch
    always_ff @(posedge clk2) begin
        if(!rst_n)  q2 <= 0;
        else        q2 <= en_clk2;
    end

    always_ff @(negedge clk2) begin
        if(!rst_n)  q4 <= 0;
        else        q4 <= q2;
    end

endmodule