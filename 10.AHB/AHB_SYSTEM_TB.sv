`timescale 1ns/1ns
import AHB_defs::*;

module TB_AHB_SYTEM;
   
   
    // Clock + Reset
    logic H_CLK;
    logic H_RESETn;

    //MASTER → SLAVE
    logic [31:0] H_ADDR;        //MASTER → SLAVE & DECODER
    logic [31:0] H_WDATA;
    H_SIZE_t     H_SIZE;
    H_BURST_t    H_BURST;
    H_TRANS_t    H_TRANS;
    logic        H_WRITE;
    logic        H_MASTLOCK;    //not implemented
    logic [3:0]  H_PROTECT;     //not implemented

    //MUX → MASTER
    logic [31:0] H_RDATA;       //Mux → Master
    logic        H_RESPONSE;    //Mux → Master
    logic        H_READY;       //MUX → MASTER & SLAVE
    //SLAVE → MUX
    logic [31:0] H_RDATA1;
    logic        H_RESPONSE1;
    logic        H_READY_OUT1;

    //DECODER → MUX & SLAVE
    logic Hsel1;     // → slave 1
    logic Hsel2;     // → slave 2
    logic Hsel3;     // → slave 3
    logic [1:0] muxSel;

    // → MASTER [Command Interface]
    logic         CMD_start;
    logic [31:0]  CMD_ADDR;
    logic         CMD_WRITE;
    H_SIZE_t      CMD_SIZE;
    H_BURST_t     CMD_BURST;
    logic [31:0]  CMD_WDATA;
    logic ready,valid;



    // Instantiate Master DUT
    AHB_master master (
        .H_CLK(H_CLK),
        .H_RESETn(H_RESETn),

        .H_SEL(),
        .H_ADDR(H_ADDR),
        .H_WDATA(H_WDATA),
        .H_SIZE(H_SIZE),
        .H_BURST(H_BURST),
        .H_PROTECT(H_PROTECT),
        .H_TRANS(H_TRANS),
        .H_WRITE(H_WRITE),
        .H_MASTLOCK(H_MASTLOCK),

        .H_READY(H_READY),
        .H_RDATA(H_RDATA),
        .H_RESPONSE(H_RESPONSE),

        .CMD_start(CMD_start),
        .CMD_ADDR(CMD_ADDR),
        .CMD_WRITE(CMD_WRITE),
        .CMD_SIZE(CMD_SIZE),
        .CMD_BURST(CMD_BURST),
        .CMD_WDATA(CMD_WDATA),
        .ready(ready),
        .valid(valid)
    );

    //Instantiate SLAVE DUT
    AHB_slave slave (
        .H_CLK(H_CLK),
        .H_RESETn(H_RESETn),
        .H_SEL(Hsel1),
        .H_RDATA(H_RDATA1),
        .H_RESPONSE(H_RESPONSE1),
        .H_READY_OUT(H_READY_OUT1),
        .H_ADDR(H_ADDR),
        .H_WDATA(H_WDATA),
        .H_SIZE(H_SIZE),
        .H_BURST(H_BURST),
        .H_PROTECT(H_PROTECT),
        .H_TRANS(H_TRANS),
        .H_WRITE(H_WRITE),
        .H_MASTLOCK(H_MASTLOCK),
        .H_READY_IN(H_READY)
    );

    AHB_decoder decoder(
        .HADDR(H_ADDR),
        .Hsel1(Hsel1),
        .Hsel2(),
        .Hsel3(),
        .muxSel(muxSel)
    );

    AHB_mux MUX (

    .H_Rdata1(H_RDATA1),
    .H_READY1(H_READY_OUT1),
    .H_RESP1(H_RESPONSE1),
    
    .H_Rdata2(),
    .H_READY2(),
    .H_RESP2(),

    .H_Rdata3(),
    .H_READY3(),
    .H_RESP3(),

    .sel(muxSel),
    .H_Rdata(H_RDATA),
    .H_READY(H_READY),
    .H_RESP(H_RESPONSE)  
    );

    // Clock
    always #5 H_CLK = ~H_CLK;

    task automatic TST_WRITE();
        $display("\n--- Starting TST_WRITE ---\n");
        
        H_CLK = 0;
        H_RESETn = 0;
        CMD_start = 0;
        CMD_ADDR = 0;
        CMD_WRITE = 0;
        CMD_SIZE = WORD;
        CMD_BURST = SINGLE;
        CMD_WDATA = 0;
        //H_READY = 1;

        #20;
        H_RESETn = 1;
        #20;

        // WRITE command
        @(posedge H_CLK iff ready)
        $display("Issuing WRITE command #1 [with wait states] ...");
        CMD_WDATA = 32'h1111_1111;  //#1
        CMD_ADDR  = 32'h0000_0004;
        $display("CMD_ADDR = %h", CMD_ADDR);
        CMD_BURST = INCR4;
        CMD_WRITE = 1;
        CMD_start = 1;

        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hAAAA_AAAA;  //#2

        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hBBBB_BBBB;  //#3
        
        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hCCCC_CCCC;  //#4

    endtask

    task automatic TST_READ();
        $display("\n--- Starting TST_READ ---\n");

        // WRITE command
        @(posedge H_CLK iff ready)
        $display("Issuing WRITE command #1 [with wait states] ...");
        CMD_ADDR  = 32'h0000_0004;
        CMD_BURST = INCR4;
        CMD_WRITE = 0;
        CMD_start = 1;

        repeat(3) begin @(posedge H_CLK iff ready); end
        @(posedge H_CLK iff ready)
        CMD_start = 0;
    endtask

    initial begin
        TST_WRITE();
        TST_READ();
    end

endmodule
