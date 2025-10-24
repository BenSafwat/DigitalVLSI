`timescale 1ns/1ns

module Async_FIFOdepth_TB;

    // Parameters
    localparam DEPTH = 8;
    localparam WIDTH = 8;

    // DUT signals
    logic rst_n;
    logic wr_clk, rd_clk;
    logic wr_EN, rd_EN;
    logic full, empty;
    logic [WIDTH-1:0] data_in;
    logic [WIDTH-1:0] data_out;
    logic outDvalid;

    // Instantiate DUT
    Asyc_FIFO #(.DEPTH(DEPTH), .WIDTH(WIDTH)) DUT (
        .rst_n(rst_n),
        .wr_clk(wr_clk), .wr_EN(wr_EN),
        .rd_clk(rd_clk), .rd_EN(rd_EN),
        .full(full), .empty(empty),
        .data_in(data_in),
        .data_out(data_out), .Dout_valid(outDvalid)
    );

    // Clock generation (asynchronous)
    initial wr_clk = 0;
    always #5 wr_clk = ~wr_clk;   // 100 MHz

    initial rd_clk = 0;
    always #8 rd_clk = ~rd_clk;   // 62.5 MHz

    // queue Variables for checking data integrity
    logic [WIDTH-1:0] write_data [$];
    logic [WIDTH-1:0] write_dataLost [$];
    logic [WIDTH-1:0] read_data [$];

    // Reset procedure
    initial begin
        rst_n = 0;
        wr_EN = 0;
        rd_EN = 0;
        data_in = '0;
        #50;
        rst_n = 1;
    end

    // Write process
    initial begin
        wait(rst_n);    //wait here until rst_n becomes 1
        repeat (40) begin   //repeat the 40 times (burst Size)
            @(posedge wr_clk);  //susbend the execution here until a positve edge of the wr_clk appears
            data_in <= $urandom_range(0, 255);  //generate the data anyway
            wr_EN <= 1;                         //ask for writing permision

            if (!full) begin //the FIFO souldn't be full as we calculated it correct size
                write_data.push_back(data_in);
                $display("WRITE success: %0d", data_in);
            end else begin
                write_dataLost.push_back(data_in);
                $display("WRITE Failed: %0d", data_in);
            end
        end
        wr_EN <= 0;
    end

    // Read process
    initial begin
        wait(rst_n);
        repeat (40) begin
            @(posedge rd_clk);
            rd_EN <= 1;

            if (outDvalid) begin
                read_data.push_back(data_out);
                $display("READ success: %0d",data_out);
            end
        end
        rd_EN <= 0;
    end

    // Check data integrity at the end
    initial begin
        #2000;
        if (read_data.size() > 0) begin
            int n = (write_data.size() < read_data.size()) ? write_data.size() : read_data.size(); // n the smaller size between read and write sizes
            int errors = 0;
            
            for (int i = 0; i < n; i++) begin
                if (read_data[i] !== write_data[i]) begin
                    $display("❌ DATA MISMATCH at index %0d: Wrote %0d, Read %0d", i, write_data[i], read_data[i]);
                    errors++;
                end
            end
           
            if (errors == 0)    $display("✅ TEST PASSED: All %0d entries matched!", n);
            else                $display("⚠️ TEST FAILED: %0d mismatches found!", errors);

        end else begin
            $display("⚠️ No data read. Check enable signals.");
        end

        for (int i = 0; i < write_dataLost.size() ; i++) begin
            $display("Lost data %0h", write_dataLost[i]);
        end
        //$finish;
    end

endmodule
