`timescale 1ns / 1ps

module dot_product_tb;

    reg clk;
    reg [15:0] SW;
    reg BTNC;
    
    wire [6:0] seg;
    wire [3:0] anode;
    wire dp;
    wire [15:0] led;

    Dot_product_top dut (
        .clk(clk),
        .SW(SW),
        .BTNC(BTNC),
        .seg(seg),
        .anode(anode),
        .dp(dp),
        .led(led)
    );


    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end


    initial begin
        $display("start of sim");

        SW = 16'h0000;
        BTNC = 1'b0;

        $display("Reset test");
        BTNC = 1'b1; 
        #10001000;  
        BTNC = 1'b0; 
        $display("Reset applied. System state should be cleared");
        #50;

        $display("Normal test: a=1,2,3,4 B=5,6,7,8");
        
        // Vector a
        write_vector_element(12, 0, 8'd1); 
        write_vector_element(12, 1, 8'd2); 
        write_vector_element(12, 2, 8'd3); 
        write_vector_element(12, 3, 8'd4); 

        // Vector B
        write_vector_element(13, 0, 8'd5); 
        write_vector_element(13, 1, 8'd6); 
        write_vector_element(13, 2, 8'd7); 
        write_vector_element(13, 3, 8'd8); 
        
        $display("stuff written");
        SW[15:14] = 2'b00;
        #20;
        SW[15:14] = 2'b11; 
        #20; 
        SW[15:14] = 2'b11;
        #100; 
        
        $display("Calculation complete. Expected 0046 Got %h", led);
        #10000;


        $display("Checking Overflow");
        
        write_vector_element(12, 0, 8'd255); 
        write_vector_element(13, 0, 8'd255); 
        write_vector_element(12, 1, 8'd255); 
        write_vector_element(13, 1, 8'd255); 

        SW[15:14] = 2'b00;
        #20;
        SW[15:14] = 2'b11;
        #100;
        
        $display("Overflow Expected FC37. got %h", led);
        #10000;

        $display("yay finish");
        $finish;
    end

    task write_vector_element;
        input [4:0] write_enable_bit;
        input [1:0] index;
        input [7:0] data;
    begin
        SW[15:12] = (1 << (write_enable_bit - 12)); 
        SW[9:8] = index;
        SW[7:0] = data;
        
        #20;
        
        SW[15:12] = 4'b0000;
        #10;
    end
    endtask

endmodule


