 module datapath(
    input clk, enable, reset_n,ld_x, ld_y, ld_c,
    input [4:0] register,
    input [5:0] addr,
    input [39:0] data, 
    output [7:0] x_out,
    output [6:0] y_out,
    output [2:0] c_out
    );
    reg [7:0] x;
    reg [6:0] y;
    reg [2:0] c;
    wire [3:0] count;
    wire reset_c;
    wire reset_s;

    localparam  S_LOAD      = 4'd0,
                S_WRITE     = 4'd1;
    reg current_state, next_state;

    always @ (posedge clk) begin
        if (!reset_n) begin
            x <= 8'd0;
            y <= 7'd0;
            c <= 3'd0; 
        end
        else begin 
            if(ld_x)
                x <= addr * 4;
            if(ld_y)
                y <= register * 4;
            if(ld_c)
                c <= (data[addr] == 0) ? 111 : 000;
         end
    end

    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD: next_state = ld_x ? S_WRITE : S_LOAD;
                S_WRITE: next_state = ld_x ? S_LOAD : S_WRITE; 
            default:     next_state = S_LOAD;
        endcase
    end // state_table

// current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!reset_n)
            current_state <= S_LOAD;
        else begin
            if(current_state == S_WRITE)
                begin if (count == {4{1'b1}})
                    current_state <= next_state;
                end
            else
                current_state <= next_state;
        end
    end // state_FFS

    assign reset_s = (current_state == S_LOAD) ? 0 : 1;
    assign reset_c = reset_n & !ld_x & !ld_y & reset_s;
    counter4bit c0(
        .out(count),
        .enable(enable),
        .reset_n(reset_c),
        .clk(clk)
        );
    
    
    assign x_out = x + count[1:0];
    assign y_out = y + count[3:2];
    assign c_out = c;

endmodule

module counter4bit(out, enable, reset_n, clk);
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

