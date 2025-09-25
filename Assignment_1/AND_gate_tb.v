`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/31/2025 02:23:00 PM
// Design Name: 
// Module Name: AND_gate_tb
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


module AND_gate_tb();
    reg a,b,d,e;
    wire c,f;
    AND_gate UUT(
        .a (a),
        .b (b),
        .c (c),
        .d (d),
        .e (e),
        .f (f),
        .g (g),
        .h (h)
    );


    initial begin
    a=0;
    b=0;
    d=0;
    e=0;
    g=0;
    #10 a=1; d=1; g = 1;
    #10 b=0; a=0; g = 0; e = 1; 
    #10 a=1; b=1; d=0;
    #10 $finish;
    end
endmodule

