module RNG(
    input        clk,
    input        frame,
    input        rst,
    input  [9:0] seed_i,
    output [9:0] rand_o
);
// optimal polynomial
localparam TAP = 10'b1100100001;
// states
localparam gene  = 1'b0;
localparam valid = 1'b1;

reg state, nextstate;
reg [9:0] rand_reg, rand_reg_c;
reg [9:0] rand_out, rand_out_c;

assign rand_o = rand_out;

always@(posedge clk)begin
    if(rst) begin
        rand_out     <= 10'b0;
        rand_reg     <= seed_i;
        state        <= gene;
    end
    else if (frame) begin
        rand_out     <= rand_reg_c;
        rand_reg     <= rand_reg_c;
        state        <= gene;
    end
    else begin
        rand_out     <= rand_out_c;
        rand_reg     <= rand_reg_c;
        state        <= nextstate;
    end
end

always@(*)begin
    case(state)
        gene: begin
            rand_out_c = rand_out;
            rand_reg_c = {(rand_reg[9] ^ rand_reg[8] ^ rand_reg [5] ^ rand_reg[0]),rand_reg[9:1]};
            nextstate = valid;
        end
        valid: begin
            rand_out_c = rand_out;
            rand_reg_c = rand_reg;
            if (rand_reg>=10'd900) begin
                nextstate = gene;
            end
            else begin
                nextstate = valid;
            end
        end
    endcase
end

endmodule