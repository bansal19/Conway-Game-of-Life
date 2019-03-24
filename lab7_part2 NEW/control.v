`include "ram40x32.v"

module control(
    input clk,
    input reset_n,
    input go,

    output register,
    output addr,
    output data, 
    output reg  enable, ld_x, ld_y, ld_c, plot
    );
    output [39:0] data;
    output [4:0] register;
    output [5:0] addr;
    reg cycle, s_ld_x, s_ld_y;
    wire reset16, reset30, reset40, enable30, enable40;
    wire [3:0] count16;
    wire [4:0] count30;
    wire [5:0] count40;
    reg [3:0] current_state, next_state; 
    
    localparam  S_LOAD_REG      = 4'd0,
                S_LOAD_REG_WAIT = 4'd1,
                S_LOAD_XYC      = 4'd2,
                S_LOAD_X_WAIT   = 4'd3,
                S_LOAD_Y        = 4'd4,
                S_LOAD_Y_WAIT   = 4'd5,
                S_CYCLE_0       = 4'd6;

    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_REG: next_state = go ? S_LOAD_REG_WAIT : S_LOAD_REG;
                S_LOAD_REG_WAIT: next_state = go ? S_LOAD_REG_WAIT : S_LOAD_XYC; // Loop in current state until go signal goes low
                S_LOAD_XYC: next_state = cycle ? S_CYCLE_0 : S_LOAD_XYC; // Loop in current state until value is input
                // S_LOAD_X_WAIT: next_state = s_ld_x ? S_LOAD_X_WAIT : S_LOAD_Y; // Loop in current state until go signal goes low
                // S_LOAD_Y: next_state = s_ld_y ? S_LOAD_Y_WAIT : S_LOAD_Y; // Loop in current state until value is input
                // S_LOAD_Y_WAIT: next_state = s_ld_y ? S_LOAD_Y_WAIT : S_CYCLE_0; // Loop in current state until go signal goes low
                S_CYCLE_0: next_state = (count30 == 6'b011110) ? S_LOAD_REG : S_LOAD_XYC;

            default:     next_state = S_LOAD_REG;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        enable = 1'b0;
        plot = 1'b0;
        ld_x = 1'b0;
        ld_y = 1'b0;
        ld_c = 1'b0;        

        case (current_state)
            S_LOAD_REG_WAIT: begin
                cycle = 1'b0;
                end
            S_LOAD_XYC: begin
                ld_x = 1'b1;
                ld_c = 1'b1;
                ld_y = 1'b1;
                cycle = 1'b1;
                end
            S_LOAD_X_WAIT: begin
                s_ld_x = 1'b0;
                s_ld_y = 1'b1;
                end
            S_LOAD_Y: begin
                ld_c = 1'b1;
                ld_y = 1'b1;
                end
            S_LOAD_Y_WAIT: begin
                s_ld_y = 1'b0;
                end
            S_CYCLE_0: begin // Write pixels to buffer, repeats 16 times
                ld_c = 1'b1;
                enable = 1'b1;
                plot = 1'b1;
                end
        endcase
    end // enable_signals
    
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

    assign enable30 = ((count40 == 6'b101000) && enable40);
    assign reset30 = (current_state != S_LOAD_REG) ? 1 : 0;
    assign register = count30;
    counter30 c1(
        .out(count30),
        .enable(enable30),
        .reset_n(reset30),
        .clk(clk)
        );

    ram40x32 r0(
        .address(count30),
	.clock(clk),
	.data({40{1'b0}}),
	.wren(1'b0),
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
                if (out == 6'b101000)
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
 
