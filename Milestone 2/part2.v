// Part 2 skeleton
`include "datapath.v"
`include "control.v"

module part2
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		HEX0,								// LIFE SCORE OUTPUTS, HEX0, HEX1, HEX2
		HEX1,
		HEX2
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	output [6:0] HEX0, HEX1, HEX2;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
        wire enable,ld_x,ld_y,ld_c;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	// datapath d0(...);
    datapath d0(
        .clk(CLOCK_50),
        .enable(enable),
        .reset_n(resetn),
        .ld_x(ld_x),
        .ld_y(ld_y),
        .ld_c(ld_c),
        .data_in(SW[6:0]),
        .c_in(SW[9:7]),
        .x_out(x),
        .y_out(y),
        .c_out(colour)
        );
    // Instansiate FSM control
    // control c0(...);
    control c0(
        .clk(CLOCK_50),
        .reset_n(resetn),
        .go(KEY[3]),
        .KEY(KEY[1]),
        .enable(enable),
        .ld_x(ld_x),
        .ld_y(ld_y),
        .ld_c(ld_c),
        .plot(writeEn)
        );
		  
		//Display the Life Score on the HEX Displays
//		hex_decoder display_1(life_score[3:0], HEX0);
//		hex_decoder display_2(life_score[7:4], HEX1);
//		hex_decoder display_3(life_score[11:8], HEX2);
		
endmodule

module try(clk, reset_n, go, glide, explode, tumble, space, gun, clear, x, y, colour, life_score);
    input clk, reset_n, go, glide, explode, tumble, space, gun, clear;
    output [2:0] colour;
    output [7:0] x;
    output [6:0] y;

    wire writeEn;
	 output life_score;
    wire enable,ld_x,ld_y,ld_c;
    wire [4:0] register;
    wire [5:0] addr;
    wire [39:0] data;

    // Instantiate datapath
	// datapath d0(...);
    datapath d0(
        .clk(clk),
        .enable(enable),
        .reset_n(reset_n),
        .ld_x(ld_x),
        .ld_y(ld_y),
        .ld_c(ld_c),
        .register(register),
        .addr(addr),
        .data(data),
        .x_out(x),
        .y_out(y),
        .c_out(colour),
        .life_score(life_score)
        );
    // Instantiate FSM control
    // control c0(...);
		control c0(
        .clk(clk),
        .reset_n(reset_n),
        .go(go),
        .glide(glide),
        .explode(explode),
        .tumble(tumble),
        .space(space),
        .gun(gun),
        .clear(clear),
        .register(register),
        .addr(addr),
        .data(data),        
        .enable(enable),
		  .reset_score(life_score),
        .ld_x(ld_x),
        .ld_y(ld_y),
        .ld_c(ld_c),
        .plot(writeEn)
        );
		
endmodule



module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule