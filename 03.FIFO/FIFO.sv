module fifo
#(
    parameter DEPTH = 4,
    parameter WIDTH = 8
)(
    input logic clk, rst_n,
    input logic r_EN, w_EN,

    output logic full, empty,

    input logic [7:0] data_in,
    input logic inDvaild,

    output logic [7:0] data_out,
    output logic outDvalid
);
    localparam ADDR_W = $clog2(DEPTH);

    logic [WIDTH-1:0] FIFO [0:DEPTH-1]; //eg. [7:0] FIFO [64]
    logic [ADDR_W:0] wadd, radd;        //[6] is a wrap around bit, [5:0] is the address

//#################################### Write procedure #######################
    always_ff @(posedge clk) begin
        if(!rst_n)begin
            //for (int i = 0; i < DEPTH; i++) FIFO[i] <= 0;
            wadd <= 0;      //go to address zero at reset
        end else if(w_EN && !full && inDvaild)begin
                //write
                FIFO[wadd[ADDR_W-1:0]] <= data_in;

                //Increment to the next write address 
                //when it overflow will go back to 0
                wadd <= wadd + 1;
        end 
    end 

//#################################### Read procedure #######################
    always_ff @(posedge clk) begin

        if(!rst_n)begin
            data_out <= 0;   //remove any data existing on the output register
            radd <= 0;       //go to address zero at reset
            outDvalid <= 0;
        end else if(r_EN && !empty) begin 
            //read
            data_out <= FIFO[radd[ADDR_W-1:0]];
            outDvalid <= 1;

            //increment to the next read address
            //when it overflow will go back to 0
            radd <= radd + 1;
            
        end else outDvalid <= 0;
    end
    
    assign empty = (wadd==radd);
    assign full = ((radd[ADDR_W] != wadd[ADDR_W]) && (radd[ADDR_W-1:0] == wadd[ADDR_W-1:0]));
endmodule