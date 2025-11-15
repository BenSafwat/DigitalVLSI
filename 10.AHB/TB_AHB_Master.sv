`timescale 1ns/1ns
import AHB_defs::*;

module tb_AHB_master;

    // Clock + Reset
    logic H_CLK;
    logic H_RESETn;

    // Master I/O
    logic        H_SEL;
    logic [31:0] H_ADDR;
    logic [31:0] H_WDATA;
    H_SIZE_t     H_SIZE;
    H_BURST_t    H_BURST;
    logic [3:0]  H_PROTECT;
    H_TRANS_t    H_TRANS;
    logic        H_WRITE;
    logic        H_MASTLOCK;
    logic        H_READY;
    logic [31:0] H_RDATA;
    logic        H_RESPONSE;

    // Command interface
    logic         CMD_start;
    logic [31:0]  CMD_ADDR;
    logic         CMD_WRITE;
    H_SIZE_t      CMD_SIZE;
    H_BURST_t     CMD_BURST;
    logic [31:0]  CMD_WDATA;
    logic [31:0]  CMD_RDATA;
    logic ready,valid;

    // Instantiate DUT
    AHB_master dut (
        .H_CLK(H_CLK),
        .H_RESETn(H_RESETn),

        .H_SEL(H_SEL),
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
        .CMD_RDATA(CMD_RDATA),
        .ready(ready),
        .valid(valid)
    );

    // Simple Slave Model (always ready, fixed data return)
    initial begin
        H_RESPONSE = 0;
    end

    // Clock
    always #5 H_CLK = ~H_CLK;

    task automatic TST_WRITE();
        $display("\n--- Starting AHB Master Testbench ---\n");
        
        H_CLK = 0;
        H_RESETn = 0;
        CMD_start = 0;
        CMD_ADDR = 0;
        CMD_WRITE = 0;
        CMD_SIZE = WORD;
        CMD_BURST = SINGLE;
        CMD_WDATA = 0;
        H_READY = 1;

        #20;
        H_RESETn = 1;
        #20;

        // WRITE command
        @(posedge H_CLK iff ready)
        $display("Issuing WRITE command #1 [with wait states] ...");
        CMD_WDATA = 32'h1111_1111;  //#1
        CMD_ADDR  = 32'h0000_0100;
        CMD_BURST = INCR4;
        CMD_WRITE = 1;
        CMD_start = 1;

        @(posedge H_CLK iff ready)
        //CMD_start = 0;
        CMD_WDATA = 32'hAAAA_AAAA;  //#2

        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hBBBB_BBBB;  //#3
        
        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hCCCC_CCCC;  //#4

        //H_READY = 0; //will make ready = 0 too
        //repeat(1) begin @(posedge H_CLK); end
        //H_READY = 1;

        //@(posedge H_CLK iff (busy==0))
        @(posedge H_CLK iff ready)
        $display("Issuing WRITE command #2 [WITHOUT wait states] ...");
        CMD_ADDR  = 32'h0000_0200;
        CMD_WDATA = 32'h1111_1111;  //#1
        CMD_BURST = INCR8;
        
        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hAAAA_AAAA;  //#2

        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hBBBB_BBBB;  //#3
        
        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hCCCC_CCCC;  //#4

        @(posedge H_CLK iff ready)
        CMD_start = 0;
        CMD_WRITE = 0;

    endtask

    task automatic TST_READ();
        $display("\n--- Starting AHB Master Testbench ---\n");
        
        H_CLK = 0;
        H_RESETn = 0;
        CMD_start = 0;
        CMD_ADDR = 0;
        CMD_WRITE = 0;
        CMD_SIZE = WORD;
        CMD_BURST = SINGLE;
        CMD_WDATA = 0;
        H_READY = 1;

        #20;
        H_RESETn = 1;
        #20;

        // WRITE command
        @(posedge H_CLK iff ready)
        $display("Issuing WRITE command #1 [with wait states] ...");
        CMD_WDATA = 32'h1111_1111;  //#1
        CMD_ADDR  = 32'h0000_0100;
        CMD_BURST = INCR4;
        CMD_WRITE = 1;
        CMD_start = 1;

        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hAAAA_AAAA;  //#2

        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hBBBB_BBBB;  //#3
        
        @(posedge H_CLK iff ready)
        CMD_WDATA = 32'hCCCC_CCCC;  //#4

        H_READY = 0; //will make ready = 0 too
        repeat(1) begin @(posedge H_CLK); end
        H_READY = 1;

        // READ command
        @(posedge H_CLK iff ready)
        $display("Issuing READ command #1 [with wait states] ...");
        CMD_ADDR  = 32'h0000_0200;
        CMD_BURST = INCR4;
        CMD_WRITE = 0;  //←Read 
        CMD_start = 1;  //keep operating
        
        @(posedge H_CLK iff ready);//master sending the address on the rising edge

        @(posedge H_CLK iff ready);//slave responding on the rising edge
        H_RDATA = 32'h1111_1111;  //#1
        
        @(posedge H_CLK iff ready)
        H_RDATA = 32'hAAAA_AAAA;  //#2

        @(posedge H_CLK iff ready)
        H_RDATA = 32'hBBBB_BBBB;  //#3
        CMD_WRITE = 1;
        CMD_start = 0;
        
        @(posedge H_CLK iff ready)
        H_RDATA = 32'hCCCC_CCCC;  //#4

        //@(posedge H_CLK iff ready)

    endtask

    // Test sequence
    initial begin
        TST_WRITE();
        //TST_READ();
    end

endmodule
