
module ClockDividerBY3 (
    input logic clk,
    input logic rst,
    output logic clkD3
);
    logic Da, Qa;
    logic Qb;
    logic Qo;

    always_comb begin: B1
        assign Da = ~Qa & ~Qb;
        assign clkD3 = Qb | Qo;
    end: B1

    always_ff @(posedge clk) begin
        if(rst)begin
            Qa <= 0;
            Qb <= 0;
        end
        else begin
            Qa <= Da;
            Qb <= Qa;
        end 
    end

    always_ff @(negedge clk) begin
        if(rst)begin
            Qo <= 0;
        end
        else begin
            Qo <= Qb;
        end
    end 
endmodule