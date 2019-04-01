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
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

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
  
        wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn, reset_score;
        wire enable,ld_x_wire,ld_y_wire,ld_c_wire;
        wire [4:0] register;
        wire [5:0] addr;
        wire [39:0] data;
	
    wire clk, reset_n, go, glide, explode, tumble, space, gun, clear;
    wire [11:0] life_score;


	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(KEY[1]),
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
    
    // Instantiate datapath
	// datapath d0(...);
    datapath d0(
        .clk(CLOCK_50),
        .enable(enable),
        .reset_n(KEY[1]),
        .ld_x(ld_x_wire),
        .ld_y(ld_y_wire),
        .ld_c(ld_c_wire),
        .reset_score(reset_score),
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
        .clk(CLOCK_50),
        .reset_n(KEY[1]),
        .reset_score(reset_score),
        .go(!KEY[0]),
        .glide(!KEY[2]),
        .explode(!KEY[3]),
        .tumble(SW[0]),
        .space(SW[1]),
        .gun(SW[2]),
        .clear(SW[3]),
        .register(register),
        .addr(addr),
        .data(data),        
        .enable(enable),
        .ld_x(ld_x_wire),
        .ld_y(ld_y_wire),
        .ld_c(ld_c_wire),
        .plot(writeEn)
        );
endmodule

module try(clk, reset_n, go, stop, glide, explode, tumble, space, gun, clear, x, y, colour, life_score, x_mouse, y_mouse, mouse_click);
    input clk, reset_n, go, stop, glide, explode, tumble, space, gun, clear, mouse_click;
    output [2:0] colour;
    output [7:0] x;
    output [6:0] y;
    output [11:0] life_score;
    input [9:0] x_mouse, y_mouse;

    wire writeEn, reset_score, logic, swap;
	wire [2:0] adj_wire;
    wire enable,ld_x_wire,ld_y_wire,ld_c_wire, mouse_plot_wire;
    wire [4:0] register;
    wire [5:0] addr_wire;
    wire [39:0] data, temp_data;

    // Instansiate datapath
	// datapath d0(...);
    datapath d0(
        .clk(clk),
        .enable(enable),
        .reset_n(reset_n),
        .ld_x(ld_x_wire),
        .ld_y(ld_y_wire),
        .ld_c(ld_c_wire),
        .reset_score(reset_score),
        .register(register),
        .addr(addr_wire),
        .data(data),
        .x_mouse(x_mouse),
        .y_mouse(y_mouse),
        .mouse_plot(mouse_plot_wire),
        .x_out(x),
        .y_out(y),
        .c_out(colour),
        .life_score(life_score)
        );
    // Instansiate FSM control
    // control c0(...);
    control c0(
        .clk(clk),
        .reset_n(reset_n),
        .reset_score(reset_score),
        .go(go),
        .stop(stop),
        .glide(glide),
        .explode(explode),
        .tumble(tumble),
        .space(space),
        .gun(gun),
        .clear(clear),
        .x_mouse(x_mouse),
        .y_mouse(y_mouse),
        .mouse_click(mouse_click),
        .mouse_plot(mouse_plot_wire),
        .register(register),
        .addr(addr_wire),
        .data(data),        
        .enable(enable),
        .ld_x(ld_x_wire),
        .ld_y(ld_y_wire),
        .ld_c(ld_c_wire),
        .plot(writeEn),
        .logic(logic),
        .swap(swap),
        .t(temp_data),
	.adj(adj_wire)
        );
endmodule
