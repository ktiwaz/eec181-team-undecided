module VGA_render (
	input clk,
    input game_en,
    input [7:0] VGA_R,
    input [7:0] VGA_G,
    input [7:0] VGA_B,
    input [12:0] row,
    input [12:0] col,
    input paddle1,
    input paddle2,
	input raw_paddle,
    input [12:0] ball_row,
    input [12:0] ball_col,
    input [9:0] p1_score,
    input [9:0] p2_score,
    input p1_win,
    input p2_win,

    output reg [7:0] render_R,
    output reg [7:0] render_G,
    output reg [7:0] render_B
);

wire ball;
wire p1_score_pixel, p2_score_pixel;
wire win_pixel;

reg p1_win_d1, p1_win_d2, p2_win_d1, p2_win_d2;
reg paddle1_d1, paddle1_d2, paddle2_d1, paddle2_d2;
reg raw_paddle_d1, raw_paddle_d2;

reg ball_d1, ball_d2;

reg [12:0] row_d1, col_d1, row_d2, col_d2;

reg [7:0] VGA_R_d1, VGA_R_d2;
reg [7:0] VGA_G_d1, VGA_G_d2;
reg [7:0] VGA_B_d1, VGA_B_d2;


draw_ball draw(
	.row      (row),
	.col      (col),
	.ball_row (ball_row),
	.ball_col (ball_col),
	.ball     (ball)
  );


  // 2 clock cycle latency on read for these two
  score_p1  score_p1_inst (
	.clk(clk),
    .row(row),
    .col(col),
    .score(p1_score),
    .score_pixel(p1_score_pixel)
  );

  score_p2  score_p2_inst (
	.clk(clk),
    .row(row),
    .col(col),
    .score(p2_score),
    .score_pixel(p2_score_pixel)
  );

  // 2 clock cycle latency for these
  win  win_inst (
	.clk(clk),
    .row(row),
    .col(col),
    .p1w(p1_win),
    .p2w(p2_win),
    .pixel(win_pixel)
  );

always @(*) begin
    render_R = VGA_R_d2;
    render_G = VGA_G_d2;
    render_B = VGA_B_d2;

    if(game_en) begin
		// half court
		if ( (col_d2>=310) && (col_d2<= 318)) begin
		  render_R = 8'ha0;
        render_G = 8'ha0;
        render_B = 8'ha0;
		end
		
		// field
		if ((row_d2<10'd5) || ((row_d2 >= 10'd473)&&(row_d2 <= 10'd477)) || ((((row_d2<=10'd119)&&(row_d2>=10'd0))||((row_d2>10'd359)&&(row_d2<=10'd477))) && ((col_d2<10'd5)||((col_d2>=10'd611)&&(col_d2<=10'd617)))) ) begin
		  render_R = 8'hff;
        render_G = 8'h00;
        render_B = 8'h00;
		end 

		// Score
		if ( (col_d2 >= 13'd20) && (col_d2 <= 13'd52) && (row_d2 >= 13'd20) && (row_d2 <= 13'd68) ) begin
				if (p1_score_pixel) begin
						render_R = (VGA_R_d2 >> 1);
						render_G = (VGA_G_d2 >> 1);
						render_B = (VGA_B_d2 >> 1);
				end
		end
		if ( (col_d2 >= 13'd565) && (col_d2 <= 13'd597) && (row_d2 >= 13'd20) && (row_d2 <= 13'd68) ) begin
				if (p2_score_pixel) begin
						render_R = (VGA_R_d2 >> 1);
						render_G = (VGA_G_d2 >> 1);
						render_B = (VGA_B_d2 >> 1);
				end
		end

		if(raw_paddle_d2) begin
			render_R = 8'b00000000;
			render_G = 8'b00000000;
			render_B = 8'b00000000;	
		end
	
		if(paddle1_d2) begin
			render_R = 8'b11111111;
			render_G = 8'b00000000;
			render_B = 8'b00000000;			
		end
		if(paddle2_d2) begin
			render_R = 8'b00000000;
			render_G = 8'b11111111;
			render_B = 8'b00000000;	
		end
     // end
		
		if (ball_d2) begin
			render_R = 8'b00000000;
			render_G = 8'b11111111;
			render_B = 8'b11111111;							
		end
		
		if (p1_win_d2||p2_win_d2) begin
			render_R = 8'b11111111;
			render_G = 8'b11111111;
			render_B = 8'b11111111;
			if ((row_d2>=209)&&(row_d2<=280)&&(col_d2>=181)&&(col_d2<=424))begin
				if (win_pixel) begin
					render_R = 8'h00;
					render_G = 8'h00;
					render_B = 8'h00; 
				end
			end
		end
    end 
end

always @(posedge clk) begin
	p1_win_d1  <= p1_win;
	p2_win_d1  <= p2_win;
	paddle1_d1 <= paddle1;
	paddle2_d1 <= paddle2;
	raw_paddle_d1 <= raw_paddle;
	ball_d1    <= ball;
	row_d1     <= row;
	col_d1     <= col;

	p1_win_d2  <= p1_win_d1;
	p2_win_d2  <= p2_win_d1;
	paddle1_d2 <= paddle1_d1;
	paddle2_d2 <= paddle2_d1;
	raw_paddle_d2 <= raw_paddle_d1;
	ball_d2    <= ball_d1;
	row_d2     <= row_d1;
	col_d2     <= col_d1;
	
	VGA_R_d1   <= VGA_R;
	VGA_G_d1   <= VGA_G;
	VGA_B_d1   <= VGA_B;
	
	VGA_R_d2   <= VGA_R_d1;
	VGA_G_d2   <= VGA_G_d1;
	VGA_B_d2   <= VGA_B_d1;
end

endmodule
