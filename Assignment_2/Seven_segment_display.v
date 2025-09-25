`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/07/2025 01:35:01 PM
// Design Name: 
// Module Name: Seven_segment_display
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


module Seven_segment_display(
    input [9:0] sw,
    output reg [6:0] seg,
    output [3:0] an
    );
    assign an = 4'b1110;
    always @(*) begin
    seg = 7'b1111111;
    if (sw[9]) seg = 7'b0010000;
    else if(sw[8]) seg = 7'b0000000;
    else if(sw[7]) seg = 7'b1111000;
    else if(sw[6]) seg = 7'b0000010;
    else if(sw[5]) seg = 7'b0010010;
    else if(sw[4]) seg = 7'b0011001;
    else if(sw[3]) seg = 7'b0110000;
    else if(sw[2]) seg = 7'b0100100;
    else if(sw[1]) seg = 7'b1111001;
    else if(sw[0]) seg = 7'b1000000;
    end 
                 
    
    
endmodule
