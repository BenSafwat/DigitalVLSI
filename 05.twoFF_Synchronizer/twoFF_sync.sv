// Two Flip-Flop Synchronizer
// This module implements a synchronizer for safely crossing clock domains.
// It uses two flip-flops in series to reduce metastability risks.
// Note: For multi-bit signals, ensure the input is gray-coded or a single bit
// to maintain data coherency across clock domains.

module twoFF_sync#(parameter WIDTH = 6)(
    input logic [WIDTH-1:0] inD,
    output logic [WIDTH-1:0] outD,

    input logic clk, rst_n
);
    logic [WIDTH-1:0] firstD;

    always_ff @(posedge clk, negedge rst_n)begin
        if(!rst_n)begin
            firstD <= '0;
            outD <= '0;
        end else begin
            firstD <= inD;
            outD <= firstD;
        end
    end

endmodule