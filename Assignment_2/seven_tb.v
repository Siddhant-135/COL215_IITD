`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/07/2025 02:02:08 PM
// Design Name: 
// Module Name: seven_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seven_tb();
  reg [9:0] sw;
  wire [6:0] seg;
  wire [3:0]an;
  Seven_segment_display uut(
    .sw(sw),
    .seg(seg),
    .an(an)
  );
  initial begin
    $display("Time(ns)\tSwitches\tSegments\tAnodes");
    $monitor("%0t\t%b\t%b\t%b", $time, sw, seg, an);
    
    sw = 10'b0000000001;
    #10 sw = 10'b0000000010;
    #10 sw = 10'b0000000100;
    #10 sw = 10'b0000001000;
    #10 sw = 10'b0000010000;
    #10 sw = 10'b0000100000;
    #10 sw = 10'b0001000000;
    #10 sw = 10'b0010000000;
    #10 sw = 10'b0100000000;
    #10 sw = 10'b1000000000;
    #10 sw = 10'b0100010001;
    #20 sw = 10'b0000000000;
    $finish;
   end 
endmodule 
    
    

