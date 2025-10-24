module Asyc_FIFO
#(
    parameter DEPTH = 4,
    parameter WIDTH = 8
)(
    input logic rst_n,
    
    input logic [7:0] data_in,
    input logic wr_clk, wr_EN,
    
    output logic [7:0] data_out,
    input logic rd_clk, rd_EN,
    output logic Dout_valid,

    output logic full, empty

);
    localparam ADDR_W = $clog2(DEPTH);

    logic [WIDTH-1:0] FIFO [0:DEPTH-1];                 //eg. [7:0] FIFO [0:63]
    logic [ADDR_W:0] wadd, radd;                        //[6] is a wrap around bit, [5:0] is the address
    logic [ADDR_W:0] wadd_gray, radd_gray;              //address after gray encoding
    logic [ADDR_W:0] wadd_gray_rdclk, radd_gray_wrclk;  //gray address after syncronization
    logic [ADDR_W:0] wadd_rdclk, radd_wrclk;            //binary address after syncronization

//#################################### Write procedure #######################
    
    // synchronize radd_gray to wr_clk to make correct comparison
    twoFF_sync #(.WIDTH (ADDR_W)) wr_sync (
        .inD(radd_gray),
        .outD(radd_gray_wrclk),
        .clk(wr_clk),
        .rst_n(rst_n));

    //converting the wadd_gray_rdclk to binary
    grayDecoder #(.WIDTH (ADDR_W)) wr_decoder(
        .in_gray(radd_gray_wrclk),
        .out_binary(radd_wrclk)
    );

    //generate full signal
    assign full = ((radd_wrclk[ADDR_W] != wadd[ADDR_W]) && (radd_wrclk[ADDR_W-1:0] == wadd[ADDR_W-1:0]));

    always_ff @(posedge wr_clk, negedge rst_n) begin
        if(!rst_n)begin
            wadd <= 0;      //go to address zero at reset
        end else if(wr_EN && !full)begin
                //write
                FIFO[wadd[ADDR_W-1:0]] <= data_in; 
                
                //Increment to the next write address 
                wadd <= wadd + 1;
        end 
    end 

    //encoding the write address from binary to gray for sending to read domain
    grayEncoder #(.WIDTH (ADDR_W)) wr_Encoder (.in_binary(wadd), .out_gray(wadd_gray));


//#################################### Read procedure #######################
    
    // synchronize wadd_gray to rd_clk to make correct comparison
    twoFF_sync #(.WIDTH (ADDR_W)) rd_sync (
        .inD(wadd_gray),
        .outD(wadd_gray_rdclk),
        .clk(rd_clk),
        .rst_n(rst_n));

    //converting the wadd_gray_rdclk to binary
    grayDecoder #(.WIDTH (ADDR_W)) rd_decoder(
        .in_gray(wadd_gray_rdclk),
        .out_binary(wadd_rdclk)
    );

    //generate empty signal
    assign empty = (wadd_rdclk==radd);

    //perform reading
    always_ff @(posedge rd_clk, negedge rst_n) begin

        if(!rst_n)begin
            data_out <= 0;   //remove any data existing on the output register
            radd <= 0;       //go to address zero at reset
            Dout_valid <= 0;
        end else if(rd_EN && !empty) begin 
            //read
            data_out <= FIFO[radd[ADDR_W-1:0]];
            Dout_valid <= 1;

            //increment to the next read address
            //when it overflow will go back to 0
            radd <= radd + 1;
            
        end else Dout_valid <= 0;
    end

    //encoding the read address from binary to gray for sending to write domain
    grayEncoder #(.WIDTH (ADDR_W)) rd_Encoder (.in_binary(radd), .out_gray(radd_gray));
    
endmodule