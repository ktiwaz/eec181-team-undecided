module score_p1(
	input  clk,
	input  [12:0] row,
	input  [12:0] col,
	input  [3:0]  score,
	output reg score_pixel
);

reg [0:0] score0 [0:1535];
reg [0:0] score1 [0:1535];
reg [0:0] score2 [0:1535];
reg [0:0] score3 [0:1535];
reg [0:0] score4 [0:1535];
reg [0:0] score5 [0:1535];
reg [0:0] score6 [0:1535];
reg [0:0] score7 [0:1535];
reg [0:0] score8 [0:1535];
reg [0:0] score9 [0:1535];

reg [12:0] num;

initial begin
    $readmemb("V/digits_mem/0.mem", score0);
end

initial begin
    $readmemb("V/digits_mem/1.mem", score1);
end

initial begin
    $readmemb("V/digits_mem/2.mem", score2);
end

initial begin
    $readmemb("V/digits_mem/3.mem", score3);
end

initial begin
    $readmemb("V/digits_mem/4.mem", score4);
end

initial begin
    $readmemb("V/digits_mem/5.mem", score5);
end

initial begin
    $readmemb("V/digits_mem/6.mem", score6);
end

initial begin
    $readmemb("V/digits_mem/7.mem", score7);
end

initial begin
    $readmemb("V/digits_mem/8.mem", score8);
end

initial begin
    $readmemb("V/digits_mem/9.mem", score9);
end

always@(posedge clk) begin
	num <= (row - 13'd20) * 13'd32 + (col - 13'd20);
	case(score)
		4'd0: begin
			score_pixel <= score0[num];
		end
		4'd1: begin
			score_pixel <= score1[num];		
		end
		4'd2: begin
			score_pixel <= score2[num];
		end
		4'd3: begin
			score_pixel <= score3[num];
		end
		4'd4: begin
			score_pixel <= score4[num];
		end
		4'd5: begin
			score_pixel <= score5[num];
		end
		4'd6: begin
			score_pixel <= score6[num];
		end
		4'd7: begin
			score_pixel <= score7[num];
		end
		4'd8: begin
			score_pixel <= score8[num];
		end
		4'd9: begin
			score_pixel <= score9[num];
		end
		default: begin
			score_pixel <= 1'b0;
		end
	endcase
end

endmodule