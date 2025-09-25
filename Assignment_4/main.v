`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2025 04:21:18 PM
// Design Name: 
// Module Name: main
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
module eight_bit_multiplier(
  input clk,
  input wire [7:0] d,
  input wire ifb,
  input wire ifc,
  output reg [15:0] product
);

    reg [7:0] b;
    reg [7:0] c;
    initial begin
      b <= 0; c <= 0;  
    end

    always @(posedge clk) begin
        if (ifb) b <= d;
        if (ifc) c <= d;
        product <= b * c;
    end
endmodule

/* module accumulator(
  input wire clk,
  input wire rst,
  input wire enable,
  input wire [15:0] adder,
  output reg [15:0] sum,
  output reg overflow
);
  reg [16:0] fallback;

  always @(posedge clk) begin
    if (rst) begin
      sum <= 16'h0000;
      overflow <= 1'b0;
      fallback <= 17'b0;
    end else if (enable) begin
      fallback <= sum + adder;
      if (fallback >16'hFFFF) begin
        overflow <= 1'b1;
        sum <= 16'b0;
      end else begin
        sum <= fallback[15:0];
      end
    end
  end
endmodule */

module accumulator(
  input wire clk,
  input wire rst,
  input wire enable,
  input wire [15:0] adder,
  output reg [15:0] sum,
  output reg overflow
);
  reg [16:0] next_sum; // 17-bit to detect overflow

  always @(posedge clk) begin
    if (rst) begin
      sum <= 16'h0000;
      overflow <= 1'b0;
      next_sum <= 17'b0;
    end else if (enable) begin
      // blocking assignment so we can test next_sum in the same clock
      next_sum = sum + adder;
      if (next_sum > 17'hFFFF) begin
        overflow <= 1'b1;
        sum <= 16'b0;
      end else begin
        sum <= next_sum[15:0];
      end
    end
  end
endmodule

module rising_edge_detector(
    input wire clk,

    input wire a,
    output wire b
);
  reg temp;
  always @(posedge clk) begin
        temp <= a;
    end
  assign b = ~temp & a;
endmodule

module debouncer #(
    parameter WIDTH = 6
)(
    input wire clk,
    input wire noisy_in,
    output reg clean_out
);
    reg [WIDTH-1:0] counter;
    reg temp;
    always @(posedge clk) begin
        if (noisy_in != temp) begin
            temp <= noisy_in;
            counter <= 0;
        end else begin
            counter <= counter + 1'b1;
            if (&counter) begin
                clean_out <= noisy_in;
                counter <= 0;
            end
        end
    end
endmodule

module display(
    input wire clk,
    input wire rst,
    input wire overflow,
    output reg [6:0] seg,
    output reg[3:0] anode
);
    wire [6:0] o, f, l, rst0, rst1, rst2, rst3;
    assign o = 7'b1000000;
    assign f = 7'b0001110;
    assign l = 7'b1000111;
    assign rst0 = 7'b0000111;
    assign rst1 = 7'b0010010;
    assign rst2 = 7'b0101111;
    assign rst3 = 7'b0111111;
    reg [16:0] counter;
    reg [1:0] active_anode;
    reg [29:0] timer;
    reg state;

    initial begin
    counter = 0;
    active_anode = 0;
    timer = 0;
    state = 0;
    end
    always @(posedge clk) begin
        counter <= counter + 1;

        if (counter >= 17'd999) begin
            counter <= 0;
            active_anode <= (active_anode==2'd3) ? 2'd0 : active_anode + 1;
        end

        if (rst) begin
            timer <=0;
            state<=1;

        end else begin
            if (state ==1 ) begin
                if (timer < 30'd500000000) begin
                    timer <= timer +1;
                end else begin
                    state <= 0;
                end
            end
            if (state == 0) begin
                timer <= 0;
            end
        end
    end

    always @(*) begin
        if (active_anode==2'd0) begin
            if (overflow) begin
                seg <= o;
            end else if (state) begin
                seg <= rst0;
            end else begin
                seg <= 7'b1111111;
            end
        end
        if (active_anode==2'd1) begin
            if (overflow) begin
                seg <= l;
            end else if (state) begin
                seg <= rst1;
            end else begin
                seg <= 7'b1111111;
            end
        end
        if (active_anode==2'd2) begin
            if (overflow) begin
                seg <= f;
            end else if (state) begin
                seg <= rst2;
            end else begin
                seg <= 7'b1111111;
            end
        end
        if (active_anode==2'd3) begin
            if (overflow) begin
                seg <= o;
            end else if (state) begin
                seg <= rst3;
            end else begin
                seg <= 7'b1111111;
            end
        end
    end
    always @(*) begin
        anode[0] = ~(active_anode == 2'd0);
        anode[1] = ~(active_anode == 2'd1);
        anode[2] = ~(active_anode == 2'd2);
        anode[3] = ~(active_anode == 2'd3);
   end
endmodule




module main(
    input wire clk,
    input wire btnC,
    input wire sw12,sw10, sw11,
    input wire [7:0]sw,
    output wire [15:0] led,
    output wire [6:0] seg,
    output wire [3:0] anode,
    output wire dp
);
    wire rst_clean;
    wire sw12_clean;

    debouncer #(.WIDTH(4)) db_rst(
        .clk(clk),
        .noisy_in(btnC),
        .clean_out(rst_clean)
    );
    debouncer #(.WIDTH(4)) db_sw12(
        .clk(clk),
        .noisy_in(sw12),
        .clean_out(sw12_clean)
    );

    wire sw12_red;
    rising_edge_detector red(
        .clk(clk),
        .a(sw12_clean),
        .b(sw12_red)
    );

    wire [15:0] product;

    eight_bit_multiplier mult(
        .d(sw),
        .clk(clk),
        .product (product),
        .ifb(sw10),
        .ifc(sw11)
    );

    wire is_overflow;
    wire [15:0] acc_sum;

    accumulator acc(
        .clk(clk),
        .rst(rst_clean),
        .enable(sw12_red),
        .adder(product),
        .sum(acc_sum),
        .overflow(is_overflow)
    );
    assign led = acc_sum;
    
    wire [6:0] segm;
    assign dp = 1'b1;
    display dspl(
        .clk(clk),
        .rst(rst_clean),
        .overflow(is_overflow),
        .seg(segm),
        .anode(anode)
    );
    assign seg = segm;



endmodule