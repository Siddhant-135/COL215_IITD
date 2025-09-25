module vector_adder_top(
    input clk,
    input [15:0] sw,
    input BTNC,
    output [6:0] seg,
    output [3:0] an,
    output dp
);
    assign dp = 1'b1;
    wire rst;
    wire dirty_rst;

    wire [9:0] mem_address;
    wire [3:0] rom_a_data_out;
    wire [3:0] ram_b_data_out;
    wire [4:0] ram_c_data_out_stored;

    wire ram_b_write_en;
    wire [3:0] ram_b_data_in;
    wire ram_c_write_en;
    wire [4:0] ram_c_data_in;

    debouncer db(
        .clk(clk),
        .BTNC(BTNC),
        .rst(dirty_rst)
    );

    rising_edge rs(
        .clk(clk),
        .rst(dirty_rst),
        .clean_out(rst)
    );

    memory_controller ctrl(
        .clk(clk),
        .rst(rst),
        .SW(sw),
        .rom_a_data_in(rom_a_data_out),
        .ram_b_data_in(ram_b_data_out),
        .address_out(mem_address),
        .ram_b_data_out(ram_b_data_in),
        .ram_b_write_en_out(ram_b_write_en),
        .ram_c_data_out(ram_c_data_in),
        .ram_c_write_en_out(ram_c_write_en)
    );

    display disp(
        .clk(clk),
        .rst(dirty_rst),
        .SW(sw),
        .val_A(rom_a_data_out),
        .val_B(ram_b_data_out),
        .val_C(ram_c_data_out_stored),
        .seg(seg),
        .anode(an)
    );

    dist_mem_gen_0 rom_a_inst (
      .clk(clk),
      .a(mem_address),
      .qspo(rom_a_data_out)
    );

    dist_mem_gen_1 ram_b_inst (
      .clk(clk),
      .we(ram_b_write_en),
      .a(mem_address),
      .d(ram_b_data_in),
      .qspo(ram_b_data_out)
    );

    dist_mem_gen_2 ram_c_inst (
      .clk(clk),
      .we(ram_c_write_en),
      .a(mem_address),
      .d(ram_c_data_in),
      .qspo(ram_c_data_out_stored)
    );

endmodule


//=============================================================================
// Memory Controller Module
//=============================================================================
module rising_edge(
    input clk,
    input rst,
    output reg clean_out
);
    reg temp;
    always @(posedge clk) begin
        temp <= rst;
        clean_out <= rst & ~temp;
    end
endmodule
module memory_controller(
    input clk,
    input rst,
    input [15:0] SW,
    input [3:0] rom_a_data_in,
    input [3:0] ram_b_data_in,

    output reg [9:0] address_out,
    output reg [3:0] ram_b_data_out,
    output reg       ram_b_write_en_out,
    output reg [4:0] ram_c_data_out,
    output reg       ram_c_write_en_out
);

    localparam S_INIT = 1'b0;
    localparam S_IDLE = 1'b1;

    reg state, next_state;
    reg [9:0] init_counter;

    wire [1:0] mode    = SW[15:14];
    wire [9:0] sw_addr = SW[13:4];
    wire [3:0] sw_data = SW[3:0];

    wire write_event;
    wire increment_event;

    edge_detector write_detector(
        .clk(clk),
        .rst(rst),
        .signal_in(state == S_IDLE && mode == 2'b10),
        .pulse_out(write_event)
    );

    edge_detector increment_detector(
        .clk(clk),
        .rst(rst),
        .signal_in(state == S_IDLE && mode == 2'b11),
        .pulse_out(increment_event)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= S_INIT;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_INIT: if (init_counter == 1023) begin
                next_state = S_IDLE;
            end
            S_IDLE: if (rst) begin
                next_state = S_INIT;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            init_counter <= 0;
        end

        ram_b_write_en_out <= 0;
        ram_c_write_en_out <= 0;

        case (state)
            S_INIT: begin
                if (init_counter < 1023) begin
                    init_counter <= init_counter + 1;
                end
                address_out <= init_counter;
                ram_c_data_out <= rom_a_data_in + ram_b_data_in;
                ram_c_write_en_out <= 1;
            end

            S_IDLE: begin
                address_out <= sw_addr;

                if (write_event) begin
                    ram_b_data_out <= sw_data;
                    ram_b_write_en_out <= 1;
                    ram_c_data_out <= rom_a_data_in + sw_data;
                    ram_c_write_en_out <= 1;
                end else if (increment_event) begin
                    ram_b_data_out <= ram_b_data_in + 1;
                    ram_b_write_en_out <= 1;
                    ram_c_data_out <= rom_a_data_in + (ram_b_data_in + 1);
                    ram_c_write_en_out <= 1;
                end
            end
        endcase
    end

endmodule


//=============================================================================
// Display Module
//=============================================================================
module display(
    input clk,
    input rst,
    input [15:0] SW,
    input [3:0] val_A,
    input [3:0] val_B,
    input [4:0] val_C,
    output reg [6:0] seg,
    output reg [3:0] anode
);
    localparam REFRESH_LIMIT = 20;
    localparam RESET_TIME_LIMIT = 500000; 

    reg [16:0] refresh_counter;
    reg [1:0] digit_select;
    reg [28:0] rst_timer;
    reg show_rst;
    reg [4:0] current_symbol;

    wire [6:0] seg_from_decoder;
    seven_seg_decoder decoder(.letter(current_symbol), .seg(seg_from_decoder));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            digit_select <=0;
        end
        else begin
            digit_select <= digit_select +1;
        end
    end
    
    
    always @(posedge clk) begin
        if (refresh_counter >= REFRESH_LIMIT - 1) begin
            refresh_counter <= 0;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            show_rst <= 1;
            rst_timer <= 0;
        end else if (show_rst) begin
            if (rst_timer >= RESET_TIME_LIMIT - 1) begin
                show_rst <= 0;
            end else begin
                rst_timer <= rst_timer + 1;
            end
        end
    end

    always @(*) begin
        anode = 4'b1111;
        current_symbol = 5'h15;

        if (show_rst) begin
            case (digit_select)
                3: begin anode = 4'b0111; current_symbol = 5'h11; end // -
                2: begin anode = 4'b1011; current_symbol = 5'h12; end // r
                1: begin anode = 4'b1101; current_symbol = 5'h13; end // S
                0: begin anode = 4'b1110; current_symbol = 5'h14; end // t
            endcase
        end else if (SW[15:14] == 2'b01) begin // Read Mode
            case (digit_select)
                0: begin anode = 4'b1110; current_symbol = {1'b0, val_A}; end
                1: begin anode = 4'b1101; current_symbol = {1'b0, val_B}; end
                2: begin anode = 4'b1011; current_symbol = val_C[3:0]; end
                3: begin anode = 4'b0111; current_symbol = {4'b0, val_C[4]}; end
            endcase
        end
        seg = seg_from_decoder;
    end
endmodule


//=============================================================================
// Edge Detector Module 
//=============================================================================
module edge_detector(
    input clk,
    input rst,
    input signal_in,
    output reg pulse_out
);
    reg prev_signal;

    always @(posedge clk) begin
        if (rst) begin
            prev_signal <= 0;
            pulse_out <= 0;
        end else begin
            prev_signal <= signal_in;
            pulse_out <= signal_in & ~prev_signal;
        end
    end
endmodule


//=============================================================================
// Debouncer Module
//=============================================================================
module debouncer(
    input clk,
    input BTNC,
    output reg rst
);
    reg [19:0] counter;
    reg btn_state;

    always @(posedge clk) begin
        btn_state <= BTNC;
        if (BTNC != btn_state) begin
            counter <= 0;
            rst <= 0;
        end else if (BTNC == 1) begin
            if (counter < 20'd999999) begin
                counter <= counter + 1;
            end else begin
                rst <= 1;
            end
        end else begin
            rst <= 0;
            counter <= 0;
        end
    end
endmodule


//=============================================================================
// Seven Segment Decoder 
//=============================================================================
module seven_seg_decoder(input [4:0] letter, output reg [6:0] seg);
    always @(*) begin
        case(letter)
            5'h0: seg = 7'b1000000; 5'h1: seg = 7'b1111001; 5'h2: seg = 7'b0100100;
            5'h3: seg = 7'b0110000; 5'h4: seg = 7'b0011001; 5'h5: seg = 7'b0010010;
            5'h6: seg = 7'b0000010; 5'h7: seg = 7'b1111000; 5'h8: seg = 7'b0000000;
            5'h9: seg = 7'b0010000; 5'hA: seg = 7'b0001000; 5'hB: seg = 7'b0000011;
            5'hC: seg = 7'b1000110; 5'hD: seg = 7'b0100001; 5'hE: seg = 7'b0000110;
            5'hF: seg = 7'b0001110; 5'h10: seg = 7'b1000111; 5'h11: seg = 7'b0111111;
            5'h12: seg = 7'b0101111; 5'h13: seg = 7'b0010010; 5'h14: seg = 7'b0000111;
            5'h15: seg = 7'b1111111; default: seg = 7'b1111111;
        endcase
    end
endmodule