module HSV_filter(
	input  [7:0] raw_VGA_R,
	input  [7:0] raw_VGA_G,
	input  [7:0] raw_VGA_B,
	
	input  [12:0] row,
	input  [12:0] col,

	output reg [7:0] o_VGA_R,
	output reg [7:0] o_VGA_G,
	output reg [7:0] o_VGA_B,
	output reg       o_color
);

wire signed [13:0] H_o;
wire        [7:0] S_o;
wire        [7:0] V_o;
wire        [7:0] V_thresh_r;

HSV pixel_HSV(
	.R   (raw_VGA_R),
	.G   (raw_VGA_G),
	.B   (raw_VGA_B),
	.H_o (H_o),
	.S_o (S_o),
	.V_o (V_o)
);

wire [13:0] H_u_r,H_d_r;

// We define the HSV thresholds
// The range goes from H = 0 to H = 6*S
// We define red as H between 0 and 0.25S, which we achieve using shift
assign H_u_r = {6'b0,S_o>>2}; //0.25
assign H_d_r = 0; //1.75	

assign V_thresh_r = V_o>>1;
always @(*)begin
		if (row <= 13'd477 && col <= 13'd617) begin
			o_VGA_R = raw_VGA_R;
			o_VGA_B = raw_VGA_B;
			o_VGA_G = raw_VGA_G;

			if((H_o>H_d_r)&&(H_o<H_u_r)&&(V_o>=8'd65)&&(S_o>V_thresh_r))begin
				o_color = 1'b1;

			end else begin
				o_color = 1'b0;
			end

		end else begin // Out of range
			o_VGA_R = 8'd0;
			o_VGA_G = 8'd0;
			o_VGA_B = 8'd0;
			o_color = 1'b0;
		end
end
endmodule
