`timescale 1ns / 1ps

module vector_adder_tb;

    reg clk;
    reg [15:0] SW;
    reg BTNC;

    wire [6:0] seg;
    wire [3:0] anode;
    wire dp;

    vector_adder_top dut (
        .clk(clk),
        .sw(SW),
        .BTNC(BTNC),
        .seg(seg),
        .an(anode),
        .dp(dp)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock, period = 10 ns
    end

    // helper task
    task clk_cycles(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) @(posedge clk);
        end
    endtask

    initial begin
        $display("[TEST 1] Initialise and Reset");

        SW = 16'h0000;
        BTNC = 0;
        #100;
        // Debouncer needs 1,000,000 cycles @100MHz = 10 ms = 10_000_000 ns
        BTNC = 1;
        #10_100_000; // 10,100,000 ns -> slightly more than 10 ms to be safe
        BTNC = 0;
        $display("Released BTNC");
        clk_cycles(10);
        
        
        $display("Letting the initial calculations based on pre-existing values occur");
        clk_cycles(2048); // ~20.48 us
        #20000000;
        clk_cycles(10);

        $display("\n[TEST 2] Reading initial calculated value at address 5.");
        SW = {2'b01, 10'd5, 4'h0}; // more readable
        // clk_cycles(4);
        clk_cycles(20);


        $display("\n[TEST 3] Writing value 3 to RAM0 at address 8.");
        SW = {2'b00, 10'd8, 4'h3};
        clk_cycles(4);
        SW = {2'b10, 10'd8, 4'h3};
        clk_cycles(4);
        SW = {2'b00, 10'd8, 4'h3};
        clk_cycles(4);
        SW = {2'b01, 10'd8, 4'h0}; 
        clk_cycles(200); 

        $display("\n[TEST 4] Incrementing value in RAM0 at address 8 and reading it");
        SW = {2'b00, 10'd8, 4'h0};
        clk_cycles(4);
        SW = {2'b11, 10'd8, 4'h0};
        clk_cycles(4);
        SW = {2'b00, 10'd8, 4'h0};
        clk_cycles(4);
        SW = {2'b01, 10'd8, 4'h0};
        clk_cycles(200);

        $display("Testbench finished.");
        $finish;
    end
endmodule