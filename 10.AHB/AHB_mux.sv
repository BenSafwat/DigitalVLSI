module AHB_mux (
    input  logic [31:0] H_Rdata1,H_Rdata2,H_Rdata3,
    input  logic H_READY1, H_READY2, H_READY3,
    input  logic H_RESP1, H_RESP2, H_RESP3,
    input  logic [1:0]  sel,

    output logic [31:0] H_Rdata,
    output logic H_READY, H_RESP
);

    always_comb begin
        unique case (sel)
            2'b00: begin
                H_Rdata = H_Rdata1;
                H_READY = H_READY1;
                H_RESP = H_RESP1;
            end

            2'b01: begin
                H_Rdata = H_Rdata2;
                H_READY = H_READY2;
                H_RESP = H_RESP2;
            end

            2'b10: begin
                H_Rdata = H_Rdata3;
                H_READY = H_READY3;
                H_RESP = H_RESP3;
            end

            default: begin
                H_Rdata = 32'b0;     //garbage data
                H_READY = 1'b0;     //not ready
                H_RESP = 1'b1;      //error
            end
        endcase
    end

endmodule
