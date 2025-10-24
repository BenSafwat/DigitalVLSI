
`timescale 1ns/1ns
module enco_deco_TB(); 
    logic [5:0] inBinary, outGray, outBinary;

grayEncoder Encoder_dut(
    .in_binary(inBinary),
    .out_gray(outGray)
);

grayDecoder decoder_dut(
    .in_gray(outGray),
    .out_binary(outBinary)
);

initial begin

    inBinary = 6'b100101;
    #1;
    //$display("inputBinary:%b | outputGray:%b", inBinary, outGray);
    $display("inputBinary:%b | outputGray:%b | back To Binary:%b", inBinary, outGray, outBinary);

end

endmodule
