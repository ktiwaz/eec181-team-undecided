module draw_ball(
	input [12:0] row,
	input [12:0] col,
	input [12:0] ball_row,
	input [12:0] ball_col,
//	input [4:0]  radius,
	output       ball

);

wire signed [13:0] col_s, row_s;
assign col_s = {1'b0, col};
assign row_s = {1'b0, row};

wire signed [9:0] dx = col_s - ball_col;
wire signed [9:0] dy = row_s - ball_row;
wire [29:0] dist2 = dx*dx + dy*dy;
assign ball = (dist2 <= 17'd64);

endmodule 