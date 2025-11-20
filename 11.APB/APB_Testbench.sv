`timescale 1ns/1ns

module apb_testbench;

    // Parameters
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam CLK_PERIOD = 10;  // 10ns clock period (100MHz)

    // Signals
    logic                     Pclk;
    logic                     PRESETn;

    // Requester signals (to APB bus)
    logic                     PSEL;
    logic                     PENABLE;
    logic                     PWRITE;
    logic [ADDR_WIDTH-1:0]    PADDR;
    logic [DATA_WIDTH-1:0]    PWDATA;
    logic [DATA_WIDTH-1:0]    PRDATA;
    logic                     PREADY;
    logic                     PSLVERR;

    // Requester request interface
    logic                     req_valid;
    logic                     req_ready;
    logic [ADDR_WIDTH-1:0]    req_addr;
    logic                     req_write;
    logic [DATA_WIDTH-1:0]    req_wdata;
    logic [DATA_WIDTH-1:0]    req_rdata;
    logic                     req_error;

    // =====================================================================
    //                    Module Instantiation
    // =====================================================================

    apb_requester #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) requester (
        .Pclk(Pclk),
        .PRESETn(PRESETn),
        .req_valid(req_valid),
        .req_ready(req_ready),
        .req_addr(req_addr),
        .req_write(req_write),
        .req_wdata(req_wdata),
        .req_rdata(req_rdata),
        .req_error(req_error),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    apb_completer #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(256)
    ) completer (
        .Pclk(Pclk),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    // =====================================================================
    //                    Clock Generation
    // =====================================================================
    initial begin
        Pclk = 1'b0;
        forever #(CLK_PERIOD/2) Pclk = ~Pclk;
    end

    // =====================================================================
    //                    Test Stimulus
    // =====================================================================
    initial begin
        $display("=== APB Requester and Completer Testbench ===");
        $display("Time: %0t", $time);

        // Initialize signals
        PRESETn = 1'b0;
        req_valid = 1'b0;
        req_addr = '0;
        req_write = 1'b0;
        req_wdata = '0;

        // Reset phase
        repeat(2) @(posedge Pclk);
        PRESETn = 1'b1;
        repeat(2) @(posedge Pclk);

        $display("\n--- Test 1: Write Operation ---");
        write_transaction(32'h00000001, 32'hDEADBEEF);

//$stop;

        $display("\n--- Test 2: Read Operation (read back written data) ---");
        read_transaction(32'h00000001);

//$stop;

        $display("\n--- Test 3: Write to Different Address ---");
        write_transaction(32'h00000004, 32'hCAFEBABE);
        
//$stop;

        $display("\n--- Test 4: Read from First Address (verify data) ---");
        read_transaction(32'h00000001);
        
//$stop;

        $display("\n--- Test 5: Read from Second Address ---");
        read_transaction(32'h00000004);
        
//$stop;

        $display("\n--- Test 6: Write Multiple Sequential Transactions ---");
        for (int i = 0; i < 4; i++) begin
            write_transaction(32'h00000008 + (i * 4), 32'h11111111 * (i + 1));
            //repeat(3) @(posedge Pclk);
        end
//$stop;

        $display("\n--- Test 7: Read Back Sequential Data ---");
        for (int i = 0; i < 4; i++) begin
            read_transaction(32'h00000008 + (i * 4));
            //repeat(3) @(posedge Pclk);
        end
//$stop;

        $display("\n--- Test 8: Error Test (out of range address) ---");
        write_transaction(32'hFFFFFFFF, 32'hDEADBEEF);
        
//$stop;

        repeat(10) @(posedge Pclk);
        $display("\n=== Testbench Complete ===");
$stop;
        //$finish;
    end

    // =====================================================================
    //                    Task: Write Transaction
    // =====================================================================
    task automatic write_transaction(logic [ADDR_WIDTH-1:0] addr, logic [DATA_WIDTH-1:0] data);
        $display("  Writing 0x%08h to address 0x%08h", data, addr);

        // Wait for requester to be ready
        while (!req_ready) @(posedge Pclk);

        // Send write request
        req_addr = addr;
        req_wdata = data;
        req_write = 1'b1;
        req_valid = 1'b1;

        @(posedge Pclk);
        req_valid = 1'b0;

        // Wait for completion [return to IDLE]
        while (!PREADY) @(posedge Pclk);
        @(posedge Pclk)
        $display("  Write complete. Error: %b", req_error);
    endtask

    // =====================================================================
    //                    Task: Read Transaction
    // =====================================================================
    task automatic read_transaction(logic [ADDR_WIDTH-1:0] addr);
        logic [DATA_WIDTH-1:0] read_data;

        $display("Reading from address 0x%08h", addr);

        // Wait for requester to be ready
        while (!req_ready) @(posedge Pclk);

        // Send read request
        req_addr = addr;    //assign the address to read
        req_wdata = '0;     //just to make sure to data to write
        req_write = 1'b0;   //Read
        req_valid = 1'b1;   //data is valid

        @(posedge Pclk);
        req_valid = 1'b0;   //after one clock period de-assert valid

        // Wait for completion and capture data [Return to IDLE]
        while (!PREADY) @(posedge Pclk);
        read_data = req_rdata;
        @(posedge Pclk);

        $display("  Read complete. Data: 0x%08h, Error: %b", read_data, req_error);
    endtask

    //// =====================================================================
    ////                    Waveform Dump (Optional)
    //// =====================================================================
    //initial begin
    //    $dumpfile("apb_testbench.vcd");
    //    $dumpvars(0, apb_testbench);
    //end

endmodule
