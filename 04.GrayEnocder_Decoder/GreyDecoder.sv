module grayDecoder#(parameter WIDTH = 6)
(
    input  logic [WIDTH-1:0] in_gray,
    output logic [WIDTH-1:0] out_binary
);
    assign out_binary[WIDTH-1] = in_gray[WIDTH-1];

    generate
        for(genvar i = WIDTH-2; i >= 0; i--)begin : generate_grayCode_decoder
            assign out_binary[i] = in_gray[i] ^ out_binary[i+1];
        end
    endgenerate

    //####  END resut we wanna achieve ######
    //assign out_binary[3] = in_gray[3];
    //assign out_binary[2] = in_gray[2] ^ out_binary[3];
    //assign out_binary[1] = in_gray[1] ^ out_binary[2];
    //assign out_binary[0] = in_gray[0] ^ out_binary[1];

endmodule