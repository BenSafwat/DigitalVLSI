
module ClockDividerBY3_2 (
    input logic clk,
    input logic rst,
    output logic clkD3
);
    logic Qa;
    logic Qb;
    logic Qo;
    logic rstCount;

always_comb begin
    rstCount = Qa & Qb;
    clkD3 = Qo | Qb;
end

always_ff @(posedge clk or posedge rstCount)begin
    if (rst | rstCount)begin
        Qa <= 0;
    end
    else begin
        Qa <= ~Qa;
    end
end

always_ff @(negedge Qa or posedge rstCount)begin
    if (rst | rstCount)begin
        Qb <= 0;
    end
    else begin
        Qb <= ~Qb;
    end
end

always_ff @(negedge clk)begin
    if (rst)begin
        Qo <= 0;
    end
    else begin
        Qo <= Qb;
    end
end

endmodule