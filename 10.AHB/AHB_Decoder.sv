module AHB_decoder(
    input logic [31:0] HADDR,

    output logic Hsel1, Hsel2, Hsel3,
    output logic [0:1] muxSel
);

    // Example address map:
    // Slave 1: 0x0000_0000 – 0x 0 FFF_FFFF
    // Slave 2: 0x1000_0000 – 0x 1 FFF_FFFF
    // Slave 3: 0x2000_0000 – 0x 2 FFF_FFFF

    always_comb begin
        // Default: no slave selected
        Hsel1  = 1'b0;
        Hsel2  = 1'b0;
        Hsel3  = 1'b0;
        muxSel = 2'b00;

        unique casez (HADDR[31:28])  // decode upper nibble for efficiency
            4'h0: begin
                Hsel1  = 1'b1;
                muxSel = 2'b00;
            end

            4'h1: begin
                Hsel2  = 1'b1;
                muxSel = 2'b01;
            end

            4'h2: begin
                Hsel3  = 1'b1;
                muxSel = 2'b10;
            end

            default: begin
                // No valid region → no select
                Hsel1  = 1'b0;
                Hsel2  = 1'b0;
                Hsel3  = 1'b0;
                muxSel = 2'b00;
            end
        endcase
    end

endmodule