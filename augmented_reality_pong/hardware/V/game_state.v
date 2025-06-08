module game_state(
    input clk,
    input sync,

    // Game state reset seperate from other resets
    input reset,

    // Normal vectors of each paddle
    input signed [14:0] nx1,
    input signed [14:0] ny1,
    input signed [14:0] nx2,
    input signed [14:0] ny2,

    // Parallel vectors of each paddle
	input signed [14:0] lx1,
    input signed [14:0] ly1,
    input signed [14:0] lx2,
    input signed [14:0] ly2,

    // Center coordinates of each paddle
	input [12:0] center_x1,
	input [12:0] center_y1,
	input [12:0] center_x2, 
	input [12:0] center_y2,

    output [12:0] ball_col,
    output [12:0] ball_row,
    output [9:0] p1_score,
	output [9:0] p2_score,

    // Player win conditions
	output p1w,
	output p2w
);
// need as input: 2 paddle pixel signal from box, 2 normal vector for 2 paddle, 4 coordinates to determine which edge of bouncing, need a signal indicating which side is the normal vector
// speed 
localparam radius = 5'd8;

reg signed [14:0] vx,vx_c;
reg signed [14:0] vy,vy_c;

wire signed [29:0] speed_squared_c;
reg signed [29:0] speed_squared;

assign speed_squared_c = vx*vx + vy*vy;

wire signed [13:0] center_x2s, center_y2s, center_x1s, center_y1s;

assign center_x2s = {1'b0, center_x2};
assign center_y2s = {1'b0, center_y2};

assign center_x1s = {1'b0, center_x1};
assign center_y1s = {1'b0, center_y1};


wire signed [14:0] d_x1_c, d_x2_c, d_y1_c, d_y2_c;
reg signed [14:0] d_x1, d_x2, d_y1, d_y2;


wire signed [29:0] d_par1_c, d_perp1_c, d_par2_c, d_perp2_c;
reg signed [29:0] d_par1, d_perp1, d_par2, d_perp2;

assign d_x1_c = c_ball_next- center_x1;
assign d_y1_c = r_ball_next - center_y1;

assign d_x2_c = c_ball_next- center_x2;
assign d_y2_c = r_ball_next - center_y2;

assign d_par1_c = (d_x1*lx1 + d_y1*ly1)>>>7;
assign d_perp1_c = (d_x1*nx1 + d_y1*ny1)>>>7;

assign d_par2_c = (d_x2*lx2 + d_y2*ly2)>>>7;
assign d_perp2_c = (d_x2*nx2 + d_y2*ny2)>>>7;

reg signed [14:0] c_ball, c_ball_c;
reg signed [14:0] r_ball, r_ball_c;

reg  signed [14:0] r_ball_next, c_ball_next;
wire signed [14:0] r_ball_next_c, c_ball_next_c;

assign r_ball_next_c = r_ball + vy;
assign c_ball_next_c = c_ball + vx;

reg signed [29:0] r_ball_local1, c_ball_local1;
reg signed [29:0] r_ball_local2, c_ball_local2;

reg signed [29:0] dot_n1, dot_n2, dot_l1, dot_l2;
reg signed [29:0] scale_n1x, scale_n2x, scale_l1x, scale_l2x;
reg signed [29:0] scale_n1y, scale_n2y, scale_l1y, scale_l2y;



reg [9:0] p1score, p1score_c;
reg [9:0] p2score, p2score_c;

reg p1win, p1win_c;
reg p2win, p2win_c;

assign p1_score = p1score;
assign p2_score = p2score;

assign p1w = p1win;
assign p2w = p2win;

assign ball_col = c_ball;
assign ball_row = r_ball;


always@(posedge clk)begin

	r_ball_next <= r_ball_next_c;
	c_ball_next <= c_ball_next_c;

	d_x1 <= d_x1_c;
	d_y1 <= d_y1_c;
	d_x2 <= d_x2_c;
	d_y2 <= d_y2_c;

	d_par1 <= d_par1_c;
	d_perp1 <= d_perp1_c;
	d_par2 <= d_par2_c;
	d_perp2 <= d_perp2_c;

	dot_n1 <= vx*nx1 + vy*ny1;
	dot_n2 <= vx*nx2 + vy*ny2;

	dot_l1 <= vx*lx1 + vy*ly1;
	dot_l2 <= vx*lx2 + vy*ly2;

	scale_n1x <= (2 * dot_n1 * nx1) >>> 14;
	scale_n2x <= (2 * dot_n2 * nx2) >>> 14;
	scale_n1y <= (2 * dot_n1 * ny1) >>> 14;
	scale_n2y <= (2 * dot_n2 * ny2) >>> 14;

	scale_l1x <= (2 * dot_l1 * lx1) >>> 14;
	scale_l2x <= (2 * dot_l2 * lx2) >>> 14;
	scale_l1y <= (2 * dot_l1 * ly1) >>> 14;
	scale_l2y <= (2 * dot_l2 * ly2) >>> 14;

	speed_squared <= speed_squared_c;

	if (d_perp2 >= -5) begin
		r_ball_local2 <= center_y2s + ((ly2 * d_par2) >> 7) + ((ny2 * 18) >> 7);
		c_ball_local2 <= center_x2s + ((lx2 * d_par2) >> 7) + ((nx2 * 18) >> 7);
	end else begin
		r_ball_local2 <= center_y2s + ((ly2 * d_par2) >> 7) - ((ny2 * 18) >> 7);
		c_ball_local2 <= center_x2s + ((lx2 * d_par2) >> 7) - ((nx2 * 18) >> 7);
	end
	if (d_perp1 >= -5) begin
		r_ball_local1 <= center_y1s + ((ly1 * d_par1) >> 7) + ((ny1 * 18) >> 7);
		c_ball_local1 <= center_x1s + ((lx1 * d_par1) >> 7) + ((nx1 * 18) >> 7);
	end else begin
		r_ball_local1 <= center_y1s + ((ly1 * d_par1) >> 7) - ((ny1 * 18) >> 7);
		c_ball_local1 <= center_x1s + ((lx1 * d_par1) >> 7) - ((nx1 * 18) >> 7);
	end

	vx <= vx_c;
	vy <= vy_c;
	c_ball <= c_ball_c;
	r_ball <= r_ball_c;
	p1score <= p1score_c;
	p2score <= p2score_c;
	p1win <= p1win_c;
	p2win <= p2win_c;
end

//use the position of TBLR to decide how to bounce
always@(*)begin
    vx_c = vx;
    vy_c = vy;

	c_ball_c = c_ball;
	r_ball_c = r_ball;
	
	p1score_c = p1score;
	p2score_c = p2score;
	
	p1win_c = p1win;
	p2win_c = p2win;

	if (speed_squared <= 100) begin
		if (vx > 0) begin
			vx_c = vx + 1;
		end else begin
			vx_c = vx - 1;
		end
		if (vy > 0) begin
			vy_c = vy + 1;
		end else begin
			vy_c = vy - 1;
		end
	end else if(speed_squared >= 150) begin
		if (vx > 0) begin
			vx_c = vx - 1;
		end else begin
			vx_c = vx + 1;
		end
		if (vy > 0) begin
			vy_c = vy - 1;
		end else begin
			vy_c = vy + 1;
		end
	end
	
	if(sync)begin // one frame check position
		// default ball row, col movement
		c_ball_c = c_ball + vx;
		r_ball_c = r_ball + vy;

      // bounce on the wall
		// bounce checking
		// horizontal logic
		if ((c_ball + vx + radius) >= 10'sd612) begin // right wall
			c_ball_c = 10'sd612 + 10'sd612 - c_ball - radius - radius - vx;
			vx_c = (-vx);
         // goal logic
			if((r_ball>10'd119)&&(r_ball<10'd360))begin
				p1score_c = p1score + 1;
				c_ball_c = 10'd320;
	    		r_ball_c = 10'd240;
				if (p1score == 10'd9) begin
					p1win_c = 1'b1;
		    	end
			end
		end

		if (c_ball < (10'sd4 - vx + radius)) begin // left wall
			c_ball_c = 10'sd8 - vx - c_ball + (radius << 1);
			vx_c = (-vx);
			// goal logic
			if((r_ball>10'd119)&&(r_ball<10'd360))begin
				p2score_c = p2score + 1;
				c_ball_c = 10'd320;
				r_ball_c = 10'd240;
				if (p2score == 10'd9) begin
					p2win_c = 1'b1;
				end
			end
		end

		// vertical logic
		if ((r_ball + vy + radius) >= 10'sd473) begin // bot wall
			r_ball_c = 10'sd473 + 10'sd473 - r_ball - radius - radius - vy;
			vy_c = (-vy);
		end

		if (r_ball < (10'sd4 - vy + radius)) begin // top wall
			r_ball_c = 10'sd8 - vy - r_ball + (radius << 1);
    		vy_c = (-vy);
		end


		if(!((d_par1 == 0)&&(d_perp1==0))) begin
			if ((((d_perp1 > -18) && d_perp1 < 18))) begin
				if ((d_par1 > -72)&&(d_par1 < 72)) begin
					vx_c = vx - scale_l1x;
					vy_c = vy - scale_l1y;
				end
			end

			if ((((d_par1 > -64) && d_par1 < 64))) begin
				if ((d_perp1 > -18)&&(d_perp1 < 18)) begin
					vx_c = vx - scale_n1x;
					vy_c = vy - scale_n1y;
					r_ball_c  = r_ball_local1[14:0];
					c_ball_c  = c_ball_local1[14:0];
				end
			end
		end
		if((!((d_par2 == 0)&&(d_perp2==0)))) begin
			if ((((d_perp2 > -18) && d_perp2 < 18))) begin
				if ((d_par2 > -72)&&(d_par2 < 72)) begin
					vx_c = vx - scale_l2x;
					vy_c = vy - scale_l2y;
				end
			end

			if ((((d_par2 > -64) && d_par2 < 64))) begin
				if ((d_perp2 > -18)&&(d_perp2 < 18)) begin
					vx_c = vx - scale_n2x;
					vy_c = vy - scale_n2y;
					r_ball_c = r_ball_local2[14:0];
					c_ball_c  = c_ball_local2[14:0];
				end
			end
		end

    end

    // reset logic
    if(reset)begin
		vx_c = 14'sd8;
		vy_c = 14'sd8;
		c_ball_c = 10'sd20;
		r_ball_c = 10'sd20;
		p1score_c = 10'b0;
		p2score_c = 10'b0;
		p1win_c = 1'b0;
		p2win_c = 1'b0;
	end
end

endmodule
