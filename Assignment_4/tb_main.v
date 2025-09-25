`timescale 1ns / 1ps
module tb_main;

  reg clk;
  reg btnC;
  reg sw12, sw10, sw11;
  reg [7:0] sw;
  wire [15:0] led;
  wire [6:0] seg;
  wire [3:0] anode;
  wire dp;

  main uut (
    .clk(clk),
    .btnC(btnC),
    .sw12(sw12),
    .sw10(sw10),
    .sw11(sw11),
    .sw(sw),
    .led(led),
    .seg(seg),
    .anode(anode),
    .dp(dp)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 0; btnC = 0; sw12 = 0; sw10 = 0; sw11 = 0; sw = 8'd0;

    @(posedge clk);
    btnC = 1;
    repeat (20) @(posedge clk);  
    btnC = 0;
    repeat (10) @(posedge clk);

  
    sw = 8'd3;
    sw10 = 1;
    @(posedge clk);
    sw10 = 0;
    
    sw = 8'd4;
    sw11 = 1;
    @(posedge clk);
    sw11 = 0;


    @(posedge clk);


    sw12 = 1;
    repeat (20) @(posedge clk); 
    sw12 = 0;
    repeat (5) @(posedge clk);

    $display("LED should now be 12, actual = %0d", led);

 
    sw = 8'd2; sw10 = 1; @(posedge clk); sw10 = 0;
    sw = 8'd5; sw11 = 1; @(posedge clk); sw11 = 0;
    @(posedge clk);
    sw12 = 1; repeat (20) @(posedge clk); sw12 = 0;
    repeat (5) @(posedge clk);

    $display("LED should now be 22 (12+10), actual = %0d", led);

    #200 $stop;
  end

endmodule