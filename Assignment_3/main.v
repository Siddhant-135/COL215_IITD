module seven_seg_decoder(
input [9:0] value,
output reg [6:0] seg
);

always @(*) begin
    casex (value)
        10'b1xxxxxxxxx: seg = 7'b0010000; // 9
        10'b01xxxxxxxx: seg = 7'b0000000; // 8
        10'b001xxxxxxx: seg = 7'b1111000; // 7
        10'b0001xxxxxx: seg = 7'b0000010; // 6
        10'b00001xxxxx: seg = 7'b0010010; // 5
        10'b000001xxxx: seg = 7'b0011001; // 4
        10'b0000001xxx: seg = 7'b0110000; // 3
        10'b00000001xx: seg = 7'b0100100; // 2
        10'b000000001x: seg = 7'b1111001; // 1
        10'b0000000001: seg = 7'b1000000; // 0
        default: seg = 7'b1111111; // blank
    endcase
end
endmodule

module main(
    input clk,
    input [13:0] sw,
    output reg [6:0] led,
    output [3:0] anode,
    output dp
    );

    assign dp = 1;
    
    reg [9:0] digit0, digit1, digit2, digit3;
     // capture the digits
    always @(posedge clk) begin
        if (sw[10]) digit0 <= sw[9:0];
        if (sw[11]) digit1 <= sw[9:0];
        if (sw[12]) digit2 <= sw[9:0];
        if (sw[13]) digit3 <= sw[9:0];
    end
    
    reg [16:0] counter = 0; // 17-bit counter
    reg [1:0] active_anode = 0; // 2-bit module seven_seg_decoder
    
    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter == 17'd999) begin
            counter <= 0;
            active_anode <= (active_anode==2'd3) ? 2'd0 : active_anode + 1;
        end
    end
    // temporary wire for decoder output
    wire [6:0] seg_out;
     // instantiate decoder module
    seven_seg_decoder decoder_inst(
        .value((active_anode==2'd0) ? digit0 :
        (active_anode==2'd1) ? digit1 :
        (active_anode==2'd2) ? digit2 :
        digit3),
    .seg(seg_out)
    );
     // assign to led
    always @(*) begin
        led = seg_out;
    end
     // anode logic (active-low)
    assign anode[0] = ~(active_anode == 2'd0);
    assign anode[1] = ~(active_anode == 2'd1);
    assign anode[2] = ~(active_anode == 2'd2);
    assign anode[3] = ~(active_anode == 2'd3);
endmodule 
