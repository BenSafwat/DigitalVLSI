`timescale 1ns/1ns

import AHB_defs::*;

module tb_AHB_slave;

    logic H_CLK;
    logic H_RESETn;
    logic H_SEL;
    logic [31:0] H_ADDR;
    logic [31:0] H_WDATA;
    H_SIZE_t  H_SIZE;
    H_BURST_t  H_BURST;
    logic [3:0]  H_PROTECT;
    H_TRANS_t    H_TRANS;
    logic        H_WRITE;
    logic        H_MASTLOCK;
    logic        H_READY_IN;

    logic [31:0] H_RDATA;
    logic        H_RESPONSE;
    logic        H_READY_OUT;

    // DUT
    AHB_slave dut (
        .H_CLK(H_CLK),
        .H_RESETn(H_RESETn),
        .H_SEL(H_SEL),
        .H_RDATA(H_RDATA),
        .H_RESPONSE(H_RESPONSE),
        .H_READY_OUT(H_READY_OUT),
        .H_ADDR(H_ADDR),
        .H_WDATA(H_WDATA),
        .H_SIZE(H_SIZE),
        .H_BURST(H_BURST),
        .H_PROTECT(H_PROTECT),
        .H_TRANS(H_TRANS),
        .H_WRITE(H_WRITE),
        .H_MASTLOCK(H_MASTLOCK),
        .H_READY_IN(H_READY_IN)
    );

    // Clock generation
    initial begin
        H_CLK = 0;
        forever #5 H_CLK = ~H_CLK; // 100 MHz
    end

    task Single_NonSeq;
        // Initialize signals
        H_RESETn = 0;
        H_SEL = 0;
        H_READY_IN = 1;
        H_WRITE = 0;
        H_TRANS = IDLE;
        H_ADDR = 0;
        H_WDATA = 0;

        // Reset
        #20;
        H_RESETn = 1;

        // ----------------------------------------
        // Write Transaction
        // ----------------------------------------
        @(posedge H_CLK iff H_READY_OUT == 1);
        H_SEL = 1;
        H_WRITE = 1;

        $display("\n--- WRITE 1---");
        H_TRANS = NONSEQ;
        H_SIZE = WORD;
        H_ADDR = 32'h0000_0004;   // 0100 mem index = 1

        @(posedge H_CLK iff H_READY_OUT == 1);
        $display("\n--- WRITE 2---");
        H_TRANS = NONSEQ;
        H_SIZE = HALFWORD;
        H_ADDR = 32'h0000_0008;   // 1010 -> mem index = 2
        H_WDATA = 32'h1111_AAAA;    //word of data

        @(posedge H_CLK iff H_READY_OUT == 1);
        $display("\n--- WRITE 3---");
        H_TRANS = NONSEQ;
        H_SIZE = BYTE;
        H_ADDR = 32'h0000_000C;   // word address -> mem index = 3
        H_WDATA = 32'h0000_BEBF;    //half word of data(16-bits)
        
        // ----------------------------------------
        // Read Transaction
        // ----------------------------------------
        @(posedge H_CLK iff H_READY_OUT == 1);
        H_WRITE = 0;

        $display("\n--- READ 1 ---");
        H_TRANS = NONSEQ;
        H_ADDR = 32'h0000_0004;
        H_WDATA = 32'h0000_00AA;        //byte of data
        
        @(posedge H_CLK iff H_READY_OUT == 1);
        $display("\n--- READ 2 ---");
        H_TRANS = NONSEQ;
        H_ADDR = 32'h0000_0008;

        @(posedge H_CLK iff H_READY_OUT == 1);;
        $display("\n--- READ 3 ---");
        H_TRANS = NONSEQ;
        H_ADDR = 32'h0000_000C;

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = IDLE;
    endtask

    task INCR_Burst;
        // Initialize signals
        H_RESETn = 0;
        H_SEL = 0;
        H_READY_IN = 1;
        H_WRITE = 0;
        H_TRANS = IDLE;
        H_ADDR = 0;
        H_WDATA = 0;

        // Reset
        #20;
        H_RESETn = 1;

        // ----------------------------------------
        // Write Transaction
        // ----------------------------------------
        @(posedge H_CLK iff H_READY_OUT == 1);
        H_SEL = 1;
        H_WRITE = 1;

        $display("\n--- Undefined lenght Burst using INCR burst #1---");
        H_SIZE = WORD;              //address should increase by 4
        H_BURST = INCR;             //send only the first address and the slave will increamenting by 1
        H_TRANS = NONSEQ;
        H_ADDR = 32'h0000_0004; 

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = SEQ;
        H_WDATA = 32'hAAAA_AAAA;    //Will be in address: h0000_0004 [0100 = 1]

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = SEQ;
        H_WDATA = 32'hBBBB_BBBB;    //Will be in address: h0000_0008 [1000 = 2]

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = SEQ;
        H_WDATA = 32'hCCCC_CCCC;    //Will be in address: h0000_000C [1100 = 3]

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = IDLE;

        @(posedge H_CLK iff H_READY_OUT == 1);
        //testing second burst immediatly after the first one 
        $display("\n--- Undefined lenght Burst using INCR burst #2 ---");
        H_SIZE = WORD;              //address should increase by 4
        H_BURST = INCR4;            //send only the first address and the slave will increamenting by 1
        H_TRANS = NONSEQ;
        H_ADDR = 32'h0000_0014; 

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = SEQ;
        H_WDATA = 32'hAAAA_AAAA;    //Will be in address: h0000_0014 [00(01_01)00 = 5]

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = SEQ;
        H_WDATA = 32'hBBBB_BBBB;    //Will be in address: h0000_0018 [00(01_10)00 = 6]

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = SEQ;
        H_WDATA = 32'hCCCC_CCCC;    //Will be in address: h0000_001C [00(01_11)00 = 7]

        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = SEQ;
        H_WDATA = 32'hDDDD_DDDD;    //Will be in address: h0000_0020 [00(10_00)00 = 8]

        @(posedge H_CLK iff H_READY_OUT == 1); // this is the fifth beat, but the slave obey the master and acts normally
        H_TRANS = SEQ;
        H_WDATA = 32'hEEEE_EEEE;    //Will be in address: h0000_0024 [0010_0100 = 9]

        //// ----------------------------------------
        //// Read Transaction
        //// ----------------------------------------
        //@(posedge H_CLK iff H_READY_OUT == 1);
        //H_WRITE = 0;
        //
        //$display("\n--- READ 1 ---");
        //H_TRANS = NONSEQ;
        //H_ADDR = 32'h0000_0004;
        //H_WDATA = 32'h0000_00AA;        //byte of data
        //
        //@(posedge H_CLK iff H_READY_OUT == 1);
        //$display("\n--- READ 2 ---");
        //H_TRANS = NONSEQ;
        //H_ADDR = 32'h0000_0008;
        //
        //@(posedge H_CLK iff H_READY_OUT == 1);;
        //$display("\n--- READ 3 ---");
        //H_TRANS = NONSEQ;
        //H_ADDR = 32'h0000_000C;
        
        @(posedge H_CLK iff H_READY_OUT == 1);
        H_TRANS = IDLE;
    endtask
    
    initial begin
        //Single_NonSeq();
        INCR_Burst();
    end

endmodule
