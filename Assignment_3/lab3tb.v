module tb_seven_segment_all();
    reg clk;
    reg [13:0] SW;
    wire [6:0] led;
    wire [3:0] anode;
    main uut (
    .clk(clk),
    .sw(SW),
    .led(led),
    .anode(anode)
    );
    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        SW = 14'b0;
        
        SW[10] = 1; SW[9:0] = 10'b1000000000; #10000 SW[10] = 0;
        #10000 SW[11] = 1; SW[9:0] = 10'b0100000000; #10000 SW[11] = 0;
        #10000 SW[12] = 1; SW[9:0] = 10'b0010000000; #10000 SW[12] = 0;
        #10000 SW[13] = 1; SW[9:0] = 10'b0001000000; #10000 SW[13] = 0;
        #10000 SW[12] = 1; SW[9:0] = 10'b0000000010; #10000 SW[12] = 0;
        #10000 SW[10] = 1; SW[9:0] = 10'b0000010000; #10000 SW[10] = 0;
        $stop;
    end
endmodule