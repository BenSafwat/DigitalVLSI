module AHB_mux (
    input  logic [31:0] HRdata1,
    input  logic [31:0] HRdata2,
    input  logic [31:0] HRdata3,
    input  logic [1:0]  sel,

    output logic [31:0] HRdata
);

    always_comb begin
        unique case (sel)
            2'b00: HRdata = HRdata1;
            2'b01: HRdata = HRdata2;
            2'b10: HRdata = HRdata3;
            default: HRdata = 32'b0;
        endcase
    end

endmodule
