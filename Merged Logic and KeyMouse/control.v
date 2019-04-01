`include "onehot.v"
`include "ram40x32.v"

module control(
    input clk,
    input reset_n,
    input go,
    input stop,
    input glide,
    input explode,
    input tumble,
    input space,
    input gun,
    input clear,
    input [9:0] x_mouse, y_mouse,
    input mouse_click,

    output [4:0] register,
    output [5:0] addr,
    output [39:0] data, 
    output reg  enable, ld_x, ld_y, ld_c, plot, reset_score, mouse_plot
    );

    reg [2:0] adj_score;
    reg cycle, wren, mouse, check_set, temp_wren;
    reg [39:0] data_write, reg_above, reg_below, current_reg, temp_write;
    wire [39:0] bitmask, temp_data;
    wire reset16, reset30, reset40, enable30, enable40, reset16m, reset16c, enable_rate, set, enable_swap30;
    wire reset_logic16, enable_logic40, reset_logic40, enable_logic30, reset_logic30, rate,  enable_swap4;

	wire [2:0] count_swap4;
    wire [3:0] count16c, count16m, count16, count_logic16;
    wire [4:0] address, count30, count30w, count_logic30, count_swap30; 
    wire [5:0] count40, count_logic40, set_value;
    reg [4:0] current_state, next_state, preset_state, register_logic;

    // One hot wires
    wire eq0, eq1, eq2, eq3, eq4, eq5, eq6, eq7, eq8, eq9, eq10, eq11, eq12, eq13;
    wire eq14, eq15, eq16, eq17, eq18, eq19, eq20, eq21, eq22, eq23, eq24, eq25, eq26;
    wire eq27, eq28, eq29, eq30, eq31, eq32, eq33, eq34, eq35, eq36, eq37, eq38, eq39;
    wire eq40, eq41, eq42, eq43, eq44, eq45, eq46, eq47, eq48, eq49, eq50, eq51, eq52;
    wire eq53, eq54, eq55, eq56, eq57, eq58, eq59, eq60, eq61, eq62, eq63;
    
    
    localparam  S_LOAD_REG      = 5'd0,
                S_LOAD_REG_WAIT = 5'd1,
                S_LOAD_MOUSE    = 5'd2,
                S_PRNT_MOUSE    = 5'd3,
                S_CLICK_WAIT    = 5'd4,
                S_CLICK         = 5'd5,
                S_LOAD_PRESET_WAIT  = 5'd6,
                S_LOAD_PRESET   = 5'd7,
                S_LOAD_XYC      = 5'd8,
                S_CYCLE_0       = 5'd9,
                S_LOGIC	        = 5'd10,
                S_WAIT          = 5'd11,
                P_GLIDE         = 5'd12, 
                P_EXPLODE       = 5'd13,
                P_TUMBLE        = 5'd14,
                P_SPACE         = 5'd15,
                P_GUN           = 5'd16,
                P_CLEAR         = 5'd17,
				S_SWAP			= 5'd18;

    
    assign set = glide | explode | tumble | space | gun | clear;
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_REG: next_state = go ? S_LOAD_REG_WAIT : (set ? S_LOAD_PRESET_WAIT : (mouse_click ? S_CLICK_WAIT : S_LOAD_XYC));
                S_LOAD_REG_WAIT: next_state = go ? S_LOAD_REG_WAIT : S_LOAD_XYC; // Loop in current state until go signal goes low
                S_CLICK_WAIT: next_state = mouse_click ? S_CLICK_WAIT : S_CLICK;
                S_CLICK: next_state = (count16c == 4'b1111) ? S_LOAD_REG : S_CLICK;
                S_LOAD_MOUSE: next_state = cycle ? S_PRNT_MOUSE : S_LOAD_MOUSE;
                S_PRNT_MOUSE: next_state = (count16m == 4'b1111) ? S_LOAD_REG : S_PRNT_MOUSE;
                S_LOAD_PRESET_WAIT: next_state = set ? S_LOAD_PRESET_WAIT : S_LOAD_PRESET;
                S_LOAD_PRESET: next_state = (count30w == 5'b11110) ? S_LOAD_XYC : S_LOAD_PRESET;     
                S_LOAD_XYC: next_state = cycle ? S_CYCLE_0 : S_LOAD_XYC; 
                S_CYCLE_0: next_state = (count30 == 5'b11110) ? (stop ? S_LOAD_REG : (mouse ? S_LOAD_MOUSE : S_LOGIC)) : S_LOAD_XYC;
                S_LOGIC: next_state = (count_logic30 == 5'b11110) ? S_SWAP : S_LOGIC;
                S_SWAP: next_state = (count_swap30 == 5'b11110) ? S_WAIT : S_SWAP;
                S_WAIT: next_state = (rate == {28{1'b0}}) ? S_LOAD_XYC : S_WAIT;
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
        mouse_plot = 1'b0;
        cycle = 1'b0;
        wren = 1'b0;
        reset_score = 1'b0;
        data_write = {40{1'b0}};
        adj_score = 3'b000;
        temp_wren = 1'b0;
                

        case (current_state)
            S_LOAD_REG: begin
                reset_score = 1'b0;
                mouse = !go;
                check_set = 1'b0;
                end
            S_LOAD_REG_WAIT: begin
                cycle = 1'b0;
                end
            S_LOAD_MOUSE: begin
                cycle = 1'b1;
                end
            S_PRNT_MOUSE: begin
                mouse_plot = 1'b1;
                enable = 1'b1;
                plot = 1'b1;
                end
            S_CLICK: begin
                enable = 1'b1;
                if (count16c == 4'b0001) begin
                    wren = 1'b1;
                    data_write = data ^ bitmask;
                end
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
                check_set = 1'b1;
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
                     P_GUN: begin
                        case(count30w)
			     7: data_write = {{24{1'b0}}, 2'b11, {9{1'b0}}, 2'b11, {3{1'b0}}};
			     8: data_write = {{23{1'b0}}, 3'b101, {9{1'b0}}, 2'b11, {3{1'b0}}};
			     9: data_write = {3'b011, {7{1'b0}}, 2'b11, {11{1'b0}}, 2'b11, {15{1'b0}}};		             
		             10: data_write = {3'b011, {6{1'b0}}, 3'b101, {28{1'b0}}};
		             11: data_write = {{9{1'b0}}, 2'b11, {6{1'b0}}, 2'b11, {21{1'b0}}};
		             12: data_write = {{17{1'b0}}, 3'b101, {20{1'b0}}};
		             13: data_write = {{17{1'b0}}, 1'b1, {22{1'b0}}};
		             14: data_write = {{36{1'b0}}, 4'b1100};
		             15: data_write = {{36{1'b0}}, 4'b1010};
		             16: data_write = {{36{1'b0}}, 4'b1000};
		             19: data_write = {{24{1'b0}}, 3'b111, {12{1'b0}}};
		             20: data_write = {{24{1'b0}}, 3'b100, {12{1'b0}}};
		             21: data_write = {{24{1'b0}}, 3'b010, {12{1'b0}}};
		             default: data_write = {40{1'b0}};
                        endcase
                        end
                     P_CLEAR: data_write = {40{1'b0}};
                     default: data_write = {40{1'b0}};
                endcase
                end
            end
	    S_LOGIC: begin
		enable = 1'b1;
		case(count_logic16)
		0: begin 
			if((count_logic30 - 1'b1) > 0)
			    register_logic = count_logic30 - 1;
		   end
		1: reg_above = data;
		2: register_logic = count_logic30;
		3:	current_reg = data;
		4: begin 
			if((count_logic30 + 1'b1) < 29)
			    register_logic = count_logic30 + 1;
		   end
		5: reg_below = data;
		6: begin
			temp_wren = 1'b1;
			if ((count_logic30 - 1'b1) > 0) begin //Check if above register exists, sub-checks to check columns
				if ((count_logic40 - 1'b1) > 0) begin
					 adj_score = (reg_above[39 - count_logic40 - 1]) ? adj_score + 1: adj_score;
			        end
				adj_score = (reg_above[39 - count_logic40]) ? adj_score + 1: adj_score;
				
				if ((count_logic40 + 1'b1) < 40) begin
					 adj_score = (reg_above[39 - count_logic40 + 1]) ? adj_score + 1: adj_score;
			        end
			end
						
			if ((count_logic40 - 1'b1) > 1'b0) begin
			    adj_score = (data[39 - count_logic40 - 1]) ? adj_score + 1 : adj_score;
			end
			if ((count_logic40 + 1'b1) < 40) begin
			    adj_score = (data[39 - count_logic40 + 1]) ? adj_score + 1 : adj_score;
			end
						
						
			if ((count_logic30 + 1'b1) < 30) begin //Check if below register exists, sub-checks to check columns
				if ((count_logic40 - 1'b1) > 0) begin
					adj_score = (reg_below[39 - count_logic40 - 1]) ? adj_score + 1 : adj_score;
			        end
			        
				adj_score = (reg_below[39 - count_logic40]) ? adj_score + 1 : adj_score;

				if ((count_logic40 + 1'b1) < 40) begin
					adj_score = (reg_below[39 - count_logic40 + 1]) ? adj_score + 1 : adj_score;
				end
			end
			//LOGIC OF THE GAME
			if(data[39 - count_logic40] == 1) begin
				if(adj_score < 3'b010) //Any live cell with fewer than 2 live neighbors dies
					temp_write = data & !bitmask;
				else if((adj_score == 3'b010) || (adj_score == 3'b011)) //Any live cell with two or three live neighbors lives on to the next generation
					temp_write = data | bitmask;
				else
					temp_write = data & !bitmask; //Any live cell with more than 3 live neighbors dies, as if by overpopulation
			end else begin
				if(adj_score == 3'b011)
					temp_write = data | bitmask; //Any dead cell with exactly 3 live neighbors becomes a live cell, as if by reproduction.
			    end
		    end
		endcase
              end
              S_SWAP: begin
					 	case(count_swap4)
					 		0: register_logic = count_swap30;
						 	1: begin
						 		wren = 1'b1;
						 		data_write = temp_data;
								end
						 	default: data_write = {40{1'b0}};
						endcase
          endcase 			 
	end
	//Counters for S_SWAP
    	assign enable_swap30 = (current_state == S_SWAP);	
	 	counter30 swap(
	 	.out(count_swap30),
	 	.enable(enable_swap30),
	 	.reset_n(!enable_swap30),
	 	.clk(clk)
	 	);
	 	
	 	assign enable_swap4 = (current_state == S_SWAP);
	 	counter4 swap4(
	 	.out(count_swap4),
	 	.enable(enable_swap4),
	 	.reset_n(!enable_swap4),
	 	.clk(clk)
	 	);
	 						
             
   //Counters for S_LOGIC
    assign reset_logic16 = (current_state == S_LOGIC);
    counter16 c0l(
        .out(count_logic16),
        .enable(enable),
        .reset_n(reset_logic16),
        .clk(clk)
    );
		
    assign enable_logic40 = (count_logic16 == 1'b1);
    assign reset_logic40 = current_state == S_LOGIC;
    counter40 c1l(
	.out(count_logic40),
	.enable(enable_logic40),
	.reset_n(reset_logic40),
	.clk(clk)
	);
		
    assign enable_logic30 = ((count_logic40 == 6'b100111) && enable_logic40);
    assign reset_logic30 = current_state == S_LOGIC;
    counter30 c2l(
	.out(count_logic30),
	.enable(enable_logic30),
	.reset_n(reset_logic30),
	.clk(clk)
	);
			
    //OTHER COUNTERS              
    assign reset16 = (current_state == S_CYCLE_0);
    counter16 c0(
        .out(count16),
        .enable(enable),
        .reset_n(reset16),
        .clk(clk)
        );

    assign enable40 = (count16 == {4{1'b1}});
    assign reset40 = (current_state == S_CYCLE_0);
    assign addr = count40;
    counter40 c2(
        .out(count40),
        .enable(enable40),
        .reset_n(reset40),
        .clk(clk)
        );

    assign enable30 = ((count40 == 6'b100111) && enable40); // change if 40 not 39
    assign reset30 = (current_state == S_CYCLE_0);
    assign register = count30;
    counter30 c1(
        .out(count30),
        .enable(enable30),
        .reset_n(reset30),
        .clk(clk)
        );
        
    assign reset30w = (current_state == S_LOAD_PRESET);
    counter30 w0(
        .out(count30w),
        .enable(enable),
        .reset_n(reset30w),
        .clk(clk)
        );
       
        
    assign reset16m = (current_state == S_PRNT_MOUSE);
    counter16 m0(
        .out(count16m),
        .enable(enable),
        .reset_n(reset16m),
        .clk(clk)
        );
        
    assign reset16c = (current_state == S_CLICK);
    counter16 c3(
        .out(count16c),
        .enable(enable),
        .reset_n(reset16c),
        .clk(clk)
        );
    
    assign address = (current_state == S_LOGIC) ? register_logic : (current_state == S_CLICK) ? y_mouse / 4 : (current_state == S_CYCLE_0 || current_state == S_LOAD_XYC || enable40) ? count30 : (current_state == S_LOAD_PRESET) ? count30w : 5'b00000;
    ram40x32 r0(
        .address(address),
	.clock(clk),
	.data(data_write),
	.wren(wren),
	.q(data)
        );
    
    assign enable_rate = (current_state == S_WAIT);
    rate_div r2Hz(
        .out(rate),
        .enable(enable_rate),
        .reset_n(enable_rate),
        .par_load({2'b00, 26'd24999999}),
        .clk(clk)
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

    assign set_value = (current_state == S_LOGIC) ? count_logic40 :(current_state == S_CLICK) ? x_mouse / 4 : {6{1'b0}};
    onehot o0(
    .data(set_value),
    .eq0(eq0),
    .eq1(eq1),
    .eq2(eq2),
    .eq3(eq3),
    .eq4(eq4),
    .eq5(eq5),
    .eq6(eq6),
    .eq7(eq7),
    .eq8(eq8),
    .eq9(eq9),
    .eq10(eq10),
    .eq11(eq11),
    .eq12(eq12),
    .eq13(eq13),
    .eq14(eq14),
    .eq15(eq15),
    .eq16(eq16),
    .eq17(eq17),
    .eq18(eq18),
    .eq19(eq19),
    .eq20(eq20),
    .eq21(eq21),
    .eq22(eq22),
    .eq23(eq23),
    .eq24(eq24),
    .eq25(eq25),
    .eq26(eq26),
    .eq27(eq27),
    .eq28(eq28),
    .eq29(eq29),
    .eq30(eq30),
    .eq31(eq31),
    .eq32(eq32),
    .eq33(eq33),
    .eq34(eq34),
    .eq35(eq35),
    .eq36(eq36),
    .eq37(eq37),
    .eq38(eq38),
    .eq39(eq39),
    .eq40(eq40),
    .eq41(eq41),
    .eq42(eq42),
    .eq43(eq43),
    .eq44(eq44),
    .eq45(eq45),
    .eq46(eq46),
    .eq47(eq47),
    .eq48(eq48),
    .eq49(eq49),
    .eq50(eq50),
    .eq51(eq51),
    .eq52(eq52),
    .eq53(eq53),
    .eq54(eq54),
    .eq55(eq55),
    .eq56(eq56),
    .eq57(eq57),
    .eq58(eq58),
    .eq59(eq59),
    .eq60(eq60),
    .eq61(eq61),
    .eq62(eq62),
    .eq63(eq63)
    );
    assign bitmask = {eq0, eq1, eq2, eq3, eq4, eq5, eq6, eq7, eq8, eq9, eq10, eq11, eq12, eq13, eq14, eq15, eq16, eq17, eq18, eq19, eq20, eq21, eq22, eq23, eq24, eq25, eq26, eq27, eq28, eq29, eq30, eq31, eq32, eq33, eq34, eq35, eq36, eq37, eq38, eq39};

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

module rate_div(out, enable, reset_n, par_load, clk);
    input enable, reset_n, clk;
    input [27:0] par_load;
    output out;

    reg [27:0] q;

    always @(posedge clk, negedge reset_n)
    begin
        if (reset_n == 1'b0)
            q <= par_load;
        else if (enable == 1'b1)
            begin
                if (q == 0)
                    q <= par_load;
                else
                    q <= q - 1'b1;
            end
    end 

    assign out = (q == {27{1'b0}}) ? 1 : 0 ;
endmodule
