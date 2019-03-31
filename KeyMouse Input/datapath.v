 module datapath(
    input clk, enable, reset_n,ld_x, ld_y, ld_c, reset_score, mouse_plot,
    input [4:0] register,
    input [5:0] addr,
    input [39:0] data,
    input [9:0] x_mouse, y_mouse,
    output [7:0] x_out,
    output [6:0] y_out,
    output [2:0] c_out,
    output [11:0] life_score
    );
    reg [7:0] x;
    reg [6:0] y;
    reg [2:0] c;
    reg [11:0] life;
    wire [4:0] count; 
    wire [3:0] out;
    wire [2:0] count4;
    wire reset_c;
    wire reset_s;

    localparam  S_LOAD      = 4'd0,
                S_WRITE     = 4'd1;
    reg current_state, next_state;

    always @ (posedge clk) begin
        if (!reset_score) begin
            life = {12{1'b0}};
        end
        if (!reset_n) begin
            x <= 8'd0;
            y <= 7'd0;
            c <= 3'd0; 
        end
        else if (!mouse_plot) begin 
            if(ld_x)
                x <= addr * 4;
                life <= (data[39 - addr] == 1) ? life + 1 : life;
            if(ld_y)
                y <= register * 4;
            if(ld_c)
                c <= (data[39 - addr] == 0) ? 111 : 000;
         end
         else begin // printing mouse
             c <= 3'b101;
             x <= x_mouse;
             y <= y_mouse;
         end         
    end
    
    assign out = count; // (count != 0) ? count - 1: count;
    assign reset_c = reset_n & !ld_x & !ld_y;
    counter17 c0(
        .out(count),
        .enable(enable),
        .reset_n(reset_c),
        .clk(clk)
        );
        
    counter4 c1(
        .out(count4),
        .enable(enable),
        .reset_n(reset_c),
        .clk(clk)
        );
    
    
    assign x_out = !mouse_plot ? x + out[1:0] : x + count4[0];
    assign y_out = !mouse_plot ? y + out[3:2] : y + count4[1];
    assign c_out = c;
    assign life_score = life;

endmodule

module counter17(out, enable, reset_n, clk);
    input enable, reset_n, clk;
    output reg [4:0] out;

    always @(posedge clk)
    begin
        if (!reset_n)
            out <= {5{1'b0}};
        else if (enable == 1'b1)
            begin
                if (out == 5'b10000)
                    out <= {5{1'b0}};
                else
                    out <= out + 1'b1;
            end
    end 
endmodule
