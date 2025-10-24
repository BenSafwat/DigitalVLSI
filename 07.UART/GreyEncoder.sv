module grayEncoder #(parameter WIDTH = 6)(
    input  logic [WIDTH-1:0] in_binary,
    output logic [WIDTH-1:0] out_gray
);
    assign out_gray = in_binary ^ (in_binary >> 1);
    
endmodule