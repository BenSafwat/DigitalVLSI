`timescale 1ns/1ns

module tb_i2c_master_v2;

    // ------------------------------------------------------
    // Testbench signals
    // ------------------------------------------------------
    logic clk, rst_n;
    logic En_i2c;
    logic [7:0] din;
    logic [2:0] dvsr;
    logic Write;
    logic [7:0] dout;
    logic ack, ready, doneTick;
    //tri SDA, SCL;
    wand SDA, SCL;  //simulates the pullup resistor behaviour on the bus
    pullup(SDA);
    pullup(SCL);

    // ------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------
    i2c_master_v2 dut (
        .clk(clk),
        .rst_n(rst_n),
        .En_i2c(En_i2c),
        .din(din),
        .dvsr(dvsr),
        .Write(Write),
        .dout(dout),
        .ack(ack),
        .ready(ready),
        .doneTick(doneTick),
        .SDA(SDA),
        .SCL(SCL)
    );

    //pull up resistor behaviour
    //Notice we have replaced these two lines by just making the signal line [SCL & SDA] to type 'wand' 
    //logic SDA_out;
    //assign SDA_out = (SDA === 1'bz)? 1'b1 : 1'b0;

    // ------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock

    // ------------------------------------------------------
    // Test procedure
    // ------------------------------------------------------
    initial begin
        // Initialize
        rst_n = 0;
        En_i2c = 0;
        #100;
        rst_n = 1;
        #2000;

        //// WRITE data
        $display("[%0t] Sending WRITE command...", $time);
        din = 8'hA5; // data to send 10100101
        Write = 1;
        En_i2c = 1;
        //@(negedge ready)
        //En_i2c = 0;

        // Finish
        $display("[%0t] Simulation completed.", $time);
    end

endmodule
