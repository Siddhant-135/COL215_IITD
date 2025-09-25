//=============================================================================
// Main Top-Level Module (Using separate wires for vector elements)
//=============================================================================
module Dot_product_top(
    input clk,
    input [15:0] SW,
    input BTNC,
    output [6:0] seg,
    output [3:0] anode,
    output dp,
    output [15:0] led
);
    // Internal signals connecting the modules
    wire rst;
    wire en;
    wire oflo;
    wire [15:0] result;

    // Separate wires for each vector element
    wire [7:0] vec_a_0, vec_a_1, vec_a_2, vec_a_3;
    wire [7:0] vec_b_0, vec_b_1, vec_b_2, vec_b_3;

    // Module Instantiations
    debouncer db(
        .clk(clk), 
        .BTNC(BTNC), 
        .rst(rst)
    );

    capture_digits cd(
        .clk(clk), 
        .SW(SW), 
        .rst(rst), 
        .vec_a_0_out(vec_a_0), .vec_a_1_out(vec_a_1), .vec_a_2_out(vec_a_2), .vec_a_3_out(vec_a_3),
        .vec_b_0_out(vec_b_0), .vec_b_1_out(vec_b_1), .vec_b_2_out(vec_b_2), .vec_b_3_out(vec_b_3)
    );
    
    en_detector ed(
        .clk(clk), 
        .SW(SW), 
        .rst(rst), 
        .en(en)
    );

    dot_product_controller dpc(
        .clk(clk), 
        .rst(rst), 
        .start(en),
        .vec_a_0_in(vec_a_0), .vec_a_1_in(vec_a_1), .vec_a_2_in(vec_a_2), .vec_a_3_in(vec_a_3),
        .vec_b_0_in(vec_b_0), .vec_b_1_in(vec_b_1), .vec_b_2_in(vec_b_2), .vec_b_3_in(vec_b_3),
        .result_out(result), 
        .overflow(oflo)
    );
    
    display disp(
        .clk(clk), 
        .rst(rst), 
        .result(result), 
        .oflo(oflo), 
        .SW(SW),
        .vec_a_0_in(vec_a_0), .vec_a_1_in(vec_a_1), .vec_a_2_in(vec_a_2), .vec_a_3_in(vec_a_3),
        .vec_b_0_in(vec_b_0), .vec_b_1_in(vec_b_1), .vec_b_2_in(vec_b_2), .vec_b_3_in(vec_b_3),
        .seg(seg), 
        .anode(anode), 
        .dp(dp), 
        .led(led)
    );
endmodule


module mac_unit(
    input [7:0] a,
    input [7:0] b,
    input [16:0] accumulator_in,
    output [16:0] accumulator_out
);
    assign accumulator_out = accumulator_in + (a * b);
endmodule


module dot_product_controller(
    input clk,
    input rst,
    input start,
    input [7:0] vec_a_0_in, input [7:0] vec_a_1_in, input [7:0] vec_a_2_in, input [7:0] vec_a_3_in,
    input [7:0] vec_b_0_in, input [7:0] vec_b_1_in, input [7:0] vec_b_2_in, input [7:0] vec_b_3_in,
    output reg [15:0] result_out,
    output reg overflow
);
    localparam S_IDLE = 2'b00, S_CALC = 2'b01, S_DONE = 2'b10;
    reg [1:0] state, next_state;
    reg [1:0] counter;
    reg [16:0] accumulator;
    wire [16:0] next_accumulator;

    reg [7:0] mac_a_in, mac_b_in;

    always @(*) begin
        case(counter)
            2'd0: begin mac_a_in = vec_a_0_in; mac_b_in = vec_b_0_in; end
            2'd1: begin mac_a_in = vec_a_1_in; mac_b_in = vec_b_1_in; end
            2'd2: begin mac_a_in = vec_a_2_in; mac_b_in = vec_b_2_in; end
            2'd3: begin mac_a_in = vec_a_3_in; mac_b_in = vec_b_3_in; end
            // default: begin mac_a_in = 8'h0; mac_b_in = 8'h0; end
        endcase
    end
    
    mac_unit my_mac(
        .a(mac_a_in),
        .b(mac_b_in),
        .accumulator_in(accumulator),
        .accumulator_out(next_accumulator)
    );

    always @(posedge clk) begin 
        if (rst) state <= S_IDLE;
        else state <= next_state;
    end

    always @(*) begin 
        next_state = state;
        case(state)
            S_IDLE: if (start) next_state = S_CALC;
            S_CALC: if (counter == 2'd3) next_state = S_DONE;
            S_DONE: next_state = S_IDLE;
        endcase
    end

    always @(posedge clk) begin 
        if (rst) begin
            counter <= 0;
            accumulator <= 0;                                                                                                                                               
            result_out <= 0;
            overflow <= 0;
        end else begin
            case(state)
                S_IDLE: if (start) begin
                    accumulator <= 0;
                    counter <= 0;
                end
                S_CALC: begin
                    accumulator <= next_accumulator;
                    counter <= counter + 1;
                end
                S_DONE: {overflow, result_out} <= accumulator;
            endcase
        end
    end
endmodule


module capture_digits(
    input clk,
    input [15:0] SW,
    input rst,          
    output reg [7:0] vec_a_0_out, output reg [7:0] vec_a_1_out, output reg [7:0] vec_a_2_out, output reg [7:0] vec_a_3_out,
    output reg [7:0] vec_b_0_out, output reg [7:0] vec_b_1_out, output reg [7:0] vec_b_2_out, output reg [7:0] vec_b_3_out
);
    wire [1:0] index = SW[9:8];

    always @(posedge clk) begin
        if (rst) begin
            vec_a_0_out <= 8'h0; vec_a_1_out <= 8'h0; vec_a_2_out <= 8'h0; vec_a_3_out <= 8'h0;
            vec_b_0_out <= 8'h0; vec_b_1_out <= 8'h0; vec_b_2_out <= 8'h0; vec_b_3_out <= 8'h0;
        end
        else begin
            if (SW[12]) begin // Write to Vector A
                case(index)
                    2'b00: vec_a_0_out <= SW[7:0];
                    2'b01: vec_a_1_out <= SW[7:0];
                    2'b10: vec_a_2_out <= SW[7:0];
                    2'b11: vec_a_3_out <= SW[7:0];
                endcase
            end
            if (SW[13]) begin // Write to Vector B
                case(index)
                    2'b00: vec_b_0_out <= SW[7:0];
                    2'b01: vec_b_1_out <= SW[7:0];
                    2'b10: vec_b_2_out <= SW[7:0];
                    2'b11: vec_b_3_out <= SW[7:0];
                endcase
            end
        end
    end
endmodule


module display(
    input clk,
    input rst,
    input [15:0] result,
    input oflo,
    input [15:0] SW,
    input [7:0] vec_a_0_in, input [7:0] vec_a_1_in, input [7:0] vec_a_2_in, input [7:0] vec_a_3_in,
    input [7:0] vec_b_0_in, input [7:0] vec_b_1_in, input [7:0] vec_b_2_in, input [7:0] vec_b_3_in,
    output reg [6:0] seg,
    output reg [3:0] anode,
    output dp,
    output [15:0] led
);
    assign led = result;
    assign dp = 1'b1;
    
    reg [28:0] rst_timer; 
    reg [16:0] refresh_counter; 
    reg [1:0] digit_select; 
    reg show_rst; 
    reg [4:0] current_symbol;
    
    wire [6:0] seg_from_decoder;
    wire [1:0] index = SW[9:8];

    // Muxes to select correct vector element for display
    reg [7:0] selected_vec_a, selected_vec_b;

    always @(*) begin
        case(index)
            2'd0: begin selected_vec_a = vec_a_0_in; selected_vec_b = vec_b_0_in; end
            2'd1: begin selected_vec_a = vec_a_1_in; selected_vec_b = vec_b_1_in; end
            2'd2: begin selected_vec_a = vec_a_2_in; selected_vec_b = vec_b_2_in; end
            2'd3: begin selected_vec_a = vec_a_3_in; selected_vec_b = vec_b_3_in; end
            default: begin selected_vec_a = 8'h0; selected_vec_b = 8'h0; end
        endcase
    end
    
    seven_seg_decoder decoder(.letter(current_symbol), .seg(seg_from_decoder));

    always @(posedge clk) begin // Refresh counter
        if (rst) begin
            refresh_counter <= 17'b0;
            digit_select <= 2'b0;
        end else begin
        
            if (refresh_counter >= 17'd100000) begin
                refresh_counter <= 0;
                digit_select <= digit_select + 1;
            end else begin
                refresh_counter <= refresh_counter + 1;
            end
        end
    end

    always @(posedge clk) begin // Reset timer
        if (rst) begin
            show_rst <= 1;
            rst_timer <= 0;
        end else if (show_rst) begin
            if (rst_timer >= 29'd500000000) show_rst <= 0;
            else rst_timer <= rst_timer + 1;
        end
    end
    
    always @(*) begin // Display logic
        anode = 4'b1111;
        current_symbol = 5'h15; // blank

        if (show_rst) begin
            case (digit_select)
                3: begin anode = 4'b0111; current_symbol = 5'h11; end // -
                2: begin anode = 4'b1011; current_symbol = 5'h12; end // r
                1: begin anode = 4'b1101; current_symbol = 5'h13; end // S
                0: begin anode = 4'b1110; current_symbol = 5'h14; end // t
            endcase
        end
        else if (oflo) begin
            case (digit_select)
                3: begin anode = 4'b0111; current_symbol = 5'h0; end // O
                2: begin anode = 4'b1011; current_symbol = 5'hF; end // F
                1: begin anode = 4'b1101; current_symbol = 5'h10; end // L
                0: begin anode = 4'b1110; current_symbol = 5'h0; end // O
            endcase
        end
        else if (SW[14] && !SW[15]) begin // Read Vector A
            case (digit_select)
                1: begin anode = 4'b1101; current_symbol = selected_vec_a[7:4]; end
                0: begin anode = 4'b1110; current_symbol = selected_vec_a[3:0]; end
                default: anode = 4'b1111;
            endcase
        end
        else if (!SW[14] && SW[15]) begin // Read Vector B
            case (digit_select)
                1: begin anode = 4'b1101; current_symbol = selected_vec_b[7:4]; end
                0: begin anode = 4'b1110; current_symbol = selected_vec_b[3:0]; end
                default: anode = 4'b1111;
            endcase
        end
        else if (SW[14] && SW[15]) begin // Show Result
            case (digit_select)
                3: begin anode = 4'b0111; current_symbol = result[15:12]; end
                2: begin anode = 4'b1011; current_symbol = result[11:8];  end
                1: begin anode = 4'b1101; current_symbol = result[7:4];   end
                0: begin anode = 4'b1110; current_symbol = result[3:0];   end
            endcase
        end
        seg = seg_from_decoder;
    end
endmodule



module debouncer(
    input clk, 
    input BTNC, 
    output reg rst
);
    reg [19:0] counter; 
    reg curr;
    
    always @(posedge clk) begin
        curr <= BTNC;
        if (BTNC != curr) begin 
        counter <= 0; rst <= 0; 
        end
        
        else if (BTNC == 1) begin
            if (counter < 20'd999999) counter <= counter + 1;
            else rst <= 1;
        end else begin 
        rst <= 0; counter <= 0; 
        end
    end
endmodule

module en_detector(input clk, input [15:0] SW, input rst, output reg en);
    reg prev;
    always @(posedge clk) begin
        if (rst) begin prev <= 0; en <= 0; end 
        else begin
            prev <= (SW[14] && SW[15]);
            en <= (SW[14] && SW[15]) & ~prev;
        end
    end
endmodule

module seven_seg_decoder(input [4:0] letter, output reg [6:0] seg);
    always @(*) begin
        case(letter)
            5'h0: seg = 7'b1000000; // 0
            5'h1: seg = 7'b1111001; // 1
            5'h2: seg = 7'b0100100; // 2
            5'h3: seg = 7'b0110000; // 3
            5'h4: seg = 7'b0011001; // 4
            5'h5: seg = 7'b0010010; // 5
            5'h6: seg = 7'b0000010; // 6
            5'h7: seg = 7'b1111000; // 7
            5'h8: seg = 7'b0000000; // 8
            5'h9: seg = 7'b0010000; // 9
            5'hA: seg = 7'b0001000; // A
            5'hB: seg = 7'b0000011; // B
            5'hC: seg = 7'b1000110; // C
            5'hD: seg = 7'b0100001; // D
            5'hE: seg = 7'b0000110; // E
            5'hF: seg = 7'b0001110; // F
            5'h10: seg = 7'b1000111; // L
            5'h11: seg = 7'b0111111; // -
            5'h12: seg = 7'b0101111; // r
            5'h13: seg = 7'b0010010; // S
            5'h14: seg = 7'b0000111; // t
            5'h15: seg = 7'b1111111; // blank
            default: seg = 7'b1111111; // Blank
        endcase
    end
endmodule

