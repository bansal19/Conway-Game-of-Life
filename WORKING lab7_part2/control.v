
module control(
    input clk,
    input reset_n,
    input go,
    input glide,
    input explode,
    input tumble,
    input space,
    input gun,
    input clear,
    

    output [4:0] register,
    output [5:0] addr,
    output [39:0] data, 
    output reg  enable, ld_x, ld_y, ld_c, plot, reset_score
    );

    reg cycle, wren;
    reg [39:0] data_write;
    wire reset16, reset30, reset40, enable30, enable40, set;
    wire [3:0] count16;
    wire [4:0] address, count30, count30w;
    wire [5:0] count40;
    reg [3:0] current_state, next_state, preset_state; 
    
    localparam  S_LOAD_REG      = 4'd0,
                S_LOAD_REG_WAIT = 4'd1,
                S_LOAD_PRESET   = 4'd2,
                S_LOAD_XYC      = 4'd3,
                S_CYCLE_0       = 4'd4,
                P_GLIDE         = 4'd5, 
                P_EXPLODE       = 4'd6,
                P_TUMBLE        = 4'd7,
                P_SPACE         = 4'd8,
                P_GUN           = 4'd9,
                P_CLEAR         = 4'd10,
					 S_WAIT_LOGIC    = 4'd11,
					 S_LOGIC			  = 4'd12;

    
    assign set = glide | explode | tumble | space | gun | clear;
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_REG: next_state = go ? S_LOAD_REG_WAIT : (set ? S_LOAD_PRESET : S_LOAD_REG);
                S_LOAD_REG_WAIT: next_state = go ? S_LOAD_REG_WAIT : S_LOAD_XYC; // Loop in current state until go signal goes low
                S_LOAD_PRESET: next_state = (count30w == 6'b011110) ? S_LOAD_XYC : S_LOAD_PRESET;              
                S_LOAD_XYC: next_state = cycle ? S_CYCLE_0 : S_LOAD_XYC; 
                S_CYCLE_0: next_state = (count30 == 6'b011110) ? S_LOAD_REG : S_LOAD_XYC;
					 S_LOGIC: next_state = (count_30logic == 6'b011110) ? S_CYCLE_0 : S_LOGIC;
            default: next_state = S_LOAD_REG;
        endcase
    end // state_table
    
    always@(*)
	if (glide) begin
	    preset_state = P_GLIDE;
	end else if (explode) begin
	    preset_state = P_EXPLODE;
	end else if (tumble) begin
	    preset_state = P_TUMBLE;
	end else if (space) begin
	    preset_state = P_SPACE;
	end else if (gun) begin
	    preset_state = P_GUN;
	end else if (clear) begin
	    preset_state = P_CLEAR;
	end
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        enable = 1'b0;
        plot = 1'b0;
        ld_x = 1'b0;
        ld_y = 1'b0;
        ld_c = 1'b0;
        cycle = 1'b0;
        wren = 1'b0;
        reset_score = 1'b0;
        data_write = {40{1'b0}};
                

        case (current_state)
            S_LOAD_REG: begin
                reset_score = 1'b0;
                end
            S_LOAD_REG_WAIT: begin
                cycle = 1'b0;
                end
            S_LOAD_XYC: begin
                ld_x = 1'b1;
                ld_c = 1'b1;
                ld_y = 1'b1;
                cycle = 1'b1;
                end
            S_CYCLE_0: begin // Write pixels to buffer, repeats 16 times
                ld_c = 1'b1;
                enable = 1'b1;
                plot = 1'b1;
                end
            S_LOAD_PRESET: begin
                wren = 1'b1;
                enable = 1'b1;
                begin
                case(preset_state)
                     P_GLIDE: begin
		        case(count30w)
		             0: data_write = {2'b01, {38{1'b0}}};
		             1: data_write = {2'b00, 2'b11, {36{1'b0}}};
		             2: data_write = {3'b011, {37{1'b0}}};
		             default: data_write = {40{1'b0}};
                        endcase
                        end
                     P_EXPLODE: begin
		        case(count30w)
		             13: data_write = {{17{1'b0}}, 5'b10101, {18{1'b0}}};
		             14: data_write = {{17{1'b0}}, 5'b10001, {18{1'b0}}};
		             15: data_write = {{17{1'b0}}, 5'b10001, {18{1'b0}}};
		             16: data_write = {{17{1'b0}}, 5'b10001, {18{1'b0}}};
		             17: data_write = {{17{1'b0}}, 5'b10101, {18{1'b0}}};
		             default: data_write = {40{1'b0}};
                        endcase
                        end
                     P_TUMBLE: begin
		        case(count30w)
		             13: data_write = {{17{1'b0}}, 5'b11011, {18{1'b0}}};
		             14: data_write = {{17{1'b0}}, 5'b11011, {18{1'b0}}};
		             15: data_write = {{17{1'b0}}, 5'b01010, {18{1'b0}}};
		             16: data_write = {{16{1'b0}}, 7'b1010101, {17{1'b0}}};
		             17: data_write = {{16{1'b0}}, 7'b1010101, {17{1'b0}}};
		             18: data_write = {{16{1'b0}}, 7'b1100011, {17{1'b0}}};
		             default: data_write = {40{1'b0}};
                        endcase
                        end
                     P_SPACE: begin
			case(count30w)
			     13: data_write = {6'b001111, {34{1'b0}}};
			     14: data_write = {6'b010001, {34{1'b0}}};
		             15: data_write = {6'b000001, {34{1'b0}}};
		             16: data_write = {6'b010010, {34{1'b0}}};
		             default: data_write = {40{1'b0}};
                        endcase
                        end
                     P_GUN: data_write = {40{1'b0}};
                     P_CLEAR: data_write = {40{1'b0}};
                     default: data_write = {40{1'b0}};
                endcase
                end
            end
        endcase
    end
                               
    assign reset16 = (current_state == S_CYCLE_0) ? 1 : 0;
    counter16 c0(
        .out(count16),
        .enable(enable),
        .reset_n(reset16),
        .clk(clk)
        );

    assign enable40 = (count16 == {4{1'b1}});
    assign reset40 = (current_state != S_LOAD_REG) ? 1 : 0;
    assign addr = count40;
    counter40 c2(
        .out(count40),
        .enable(enable40),
        .reset_n(reset40),
        .clk(clk)
        );

    assign enable30 = ((count40 == 6'b100111) && enable40); // change if 40 not 39
    assign reset30 = (current_state != S_LOAD_REG) ? 1 : 0;
    assign register = count30;
    counter30 c1(
        .out(count30),
        .enable(enable30),
        .reset_n(reset30),
        .clk(clk)
        );
        
    assign reset30w = (current_state == S_LOAD_PRESET) ? 1 : 0;
    counter30 w0(
        .out(count30w),
        .enable(enable),
        .reset_n(reset30w),
        .clk(clk)
        );
    
    assign address = (current_state == S_CYCLE_0 || current_state == S_LOAD_XYC || enable40) ? count30 : ((current_state == S_LOAD_PRESET) ? count30w : 5'b00000);
    ram40x32 r0(
        .address(address),
	.clock(clk),
	.data(data_write),
	.wren(wren),
	.q(data)
        );

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!reset_n)
            current_state <= S_LOAD_REG;
        else begin
            if(current_state == S_CYCLE_0)
                begin if (count16 == {4{1'b1}})
                    current_state <= next_state;
                end
            else
                current_state <= next_state;
        end
    end // state_FFS
endmodule

module counter16(out, enable, reset_n, clk);
    input enable, reset_n, clk;
    output reg [3:0] out;

    always @(posedge clk)
    begin
        if (!reset_n)
            out <= {4{1'b0}};
        else if (enable == 1'b1)
            begin
                if (out == {4{1'b1}})
                    out <= {4{1'b0}};
                else
                    out <= out + 1'b1;
            end
    end 
endmodule

module counter40(out, enable, reset_n, clk);
    input enable, reset_n, clk;
    output reg [5:0] out;

    always @(posedge clk)
    begin
        if (!reset_n)
            out <= {5{1'b0}};
        else if (enable == 1'b1)
            begin
                if (out == 6'b100111) // change if 40 not 39, use (count40 == 40) ? 39 : count
                    out <= {6{1'b0}};
                else
                    out <= out + 1'b1;
            end
    end 
endmodule

module counter30(out, enable, reset_n, clk);
    input enable, reset_n, clk;
    output reg [4:0] out;

    always @(posedge clk)
    begin
        if (!reset_n)
            out <= {5{1'b0}};
        else if (enable == 1'b1)
            begin
                if (out == 5'b11110)
                    out <= {5{1'b0}};
                else
                    out <= out + 1'b1;
            end
    end 
endmodule
 
