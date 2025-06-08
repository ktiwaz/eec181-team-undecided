module win(
    input clk,
    input wire [12:0] row,     // enough for 617*478 = 294,226 < 2^19
    input wire [12:0] col,
    input p1w,
    input p2w,
    output reg pixel
);
	 
    reg [0:0] p1mem [0:17567];
    reg [0:0] p2mem [0:17567];
	 
    reg [19:0] num;
	 
    initial begin
        $readmemb("V/mem/game_over_player1_cropped.mem", p1mem);
    end

    initial begin
        $readmemb("V/mem/game_over_player2_cropped.mem", p2mem);
    end

    always @(posedge clk) begin
        num <= (row - 209) * 244 + (col - 181);
        pixel <= 1'b0;
        if(p1w)
            pixel <= p1mem[num];
        else if (p2w)
            pixel <= p2mem[num];
    end


endmodule