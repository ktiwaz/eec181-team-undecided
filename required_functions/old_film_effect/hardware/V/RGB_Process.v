module RGB_Process(
	input  [7:0] raw_VGA_R,
	input  [7:0] raw_VGA_G,
	input  [7:0] raw_VGA_B,
	input  [12:0] row,
	input  [12:0] col,
	input         VGA_VS,
	input         clk,
	input         reset_n,
	input [5:0]   filter_SW,
	input         grayscale_SW,
	input         sepia_SW,
	input         vignette_SW,
	input  [3:0]  cursor_speed,
	input         cursor_select,

	output reg [7:0] o_VGA_R,
	output reg [7:0] o_VGA_G,
	output reg [7:0] o_VGA_B
);

reg vsyncflag_c, vsyncflag;
reg state_c,     state;

localparam INIT = 1'b0;
localparam VSYNC = 1'b1;

wire signed [13:0] col_s, row_s;
assign col_s = {1'b0, col};
assign row_s = {1'b0, row};

reg [8:0] v_pos0_c, v_pos0;
reg [9:0] h_pos0_c, h_pos0;

reg [8:0] v_pos1_c, v_pos1;
reg [9:0] h_pos1_c, h_pos1;

localparam red_coeff   = 54;
localparam green_coeff = 183;
localparam blue_coeff  = 18;

wire [15:0] red_gray, green_gray, blue_gray;
wire [15:0] luminance; // 16-bit sum to avoid overflow

assign red_gray   = red_coeff * raw_VGA_R;
assign green_gray = green_coeff * raw_VGA_G;
assign blue_gray  = blue_coeff * raw_VGA_B;

// Compute final grayscale luminance value (upper 8 bits)
assign luminance = (red_gray + green_gray + blue_gray) >> 8;

wire [17:0] r_temp, g_temp, b_temp, r_shifted, g_shifted, b_shifted;
wire [7:0] r_sepia, g_sepia, b_sepia, r_vig, g_vig, b_vig;

// Integer sepia coefficients, scaled by 256
assign r_temp = (101 * raw_VGA_R) + (197 * raw_VGA_G) + ( 48 * raw_VGA_B);
assign g_temp = ( 89 * raw_VGA_R) + (176 * raw_VGA_G) + ( 43 * raw_VGA_B);
assign b_temp = ( 69 * raw_VGA_R) + (136 * raw_VGA_G) + ( 33 * raw_VGA_B);

// Clamp to 255 *after shifting
assign r_shifted = r_temp >> 8;
assign g_shifted = g_temp >> 8;
assign b_shifted = b_temp >> 8;

assign r_sepia = (r_shifted > 18'd255) ? 8'd255 : r_shifted[7:0];
assign g_sepia = (g_shifted > 18'd255) ? 8'd255 : g_shifted[7:0];
assign b_sepia = (b_shifted > 18'd255) ? 8'd255 : b_shifted[7:0];

// RNG signal
wire [9:0] rand_o [2:0];

reg [9:0] noise, noise_c;
wire draw;
wire raw_VGA_Blob;

// assign raw_VGA_Blob = (row >=rand_o[2] - 10'd2) && (row<=rand_o[2] + 10'd2) && (col>=rand_o[1] - 10'd2)&& (col<=rand_o[1] + 10'd2) && (noise > 300);
wire signed [9:0] dx = col_s - rand_o[1];
wire signed [9:0] dy = row_s - rand_o[2];
wire [17:0] dist2 = dx*dx + dy*dy;
assign raw_VGA_Blob = (dist2 < rand_o[0][3:0]) && (noise > 300);

wire signed [9:0] dxx = col_s - 13'd320;
wire signed [9:0] dyy = row_s - 13'd240;

wire [15:0] r_vig_temp, g_vig_temp, b_vig_temp;

wire [17:0] d2 = dxx*dxx + dyy*dyy;

wire [7:0] weight;

LUT i_LUT (
	.d2     ( d2[17:9] ),
	.weight ( weight)
);

assign r_vig_temp = (r_sepia * weight);
assign g_vig_temp = (g_sepia * weight);
assign b_vig_temp = (b_sepia * weight);

assign r_vig = r_vig_temp >> 8;
assign g_vig = g_vig_temp >> 8;
assign b_vig = b_vig_temp >> 8;


localparam V_HEIGHT = 5;
localparam H_HEIGHT = 5;

localparam normal = 2'b00;
localparam half   = 2'b01;
localparam quarter = 2'b10;
localparam off     = 2'b11;

always @(*)begin

	// Defaults to avoid inferred latch bruv
	o_VGA_R  = 8'd0;
	o_VGA_G  = 8'h00;
	o_VGA_B  = 8'h0;

	if (row >= 13'd0 && row <= 13'd479 && col>= 13'd0 && col < 13'd639) begin //bottom right - white
		case(filter_SW[1:0]) // Blue
			normal  : begin
				o_VGA_B = raw_VGA_B;
			end
			half    : begin
				o_VGA_B = raw_VGA_B>>1;
			end
			quarter : begin
				o_VGA_B = raw_VGA_B>>2;
			end
			off     : begin
				o_VGA_B = 8'b0;
			end
		endcase
	 
		case(filter_SW[3:2]) // Green
			normal  : begin
				o_VGA_G = raw_VGA_G;
			end
			half    : begin
				o_VGA_G = raw_VGA_G>>1;
			end
			quarter : begin
				o_VGA_G = raw_VGA_G>>2;
			end
			off     : begin
				o_VGA_G = 8'b0;
			end
		endcase
	 
		case(filter_SW[5:4]) // Red
			normal  : begin
				o_VGA_R = raw_VGA_R;
			end
			half    : begin
				o_VGA_R = raw_VGA_R>>1;
			end
			quarter : begin
				o_VGA_R = raw_VGA_R>>2;
			end
			off     : begin
				o_VGA_R = 8'b0;
			end
		endcase
		if (grayscale_SW) begin
			o_VGA_R = luminance[7:0]; // Same value for grayscale
        	o_VGA_G = luminance[7:0];
        	o_VGA_B = luminance[7:0];
		end
		if (sepia_SW) begin
			o_VGA_R = r_sepia[7:0]; // Same value for grayscale
        	o_VGA_G = g_sepia[7:0];
        	o_VGA_B = b_sepia[7:0];
		end
		if (vignette_SW) begin
			o_VGA_R = r_vig[7:0]; // Same value for grayscale
        	o_VGA_G = g_vig[7:0];
        	o_VGA_B = b_vig[7:0];
		end
	 end

	

	// Draw cursor
	if ((row > v_pos0 - V_HEIGHT) && (row < v_pos0 + V_HEIGHT) && (col > h_pos0 - H_HEIGHT) && (col < h_pos0 + H_HEIGHT)) begin
		if (((row <= v_pos0 - V_HEIGHT + 1) || (row >= v_pos0 + V_HEIGHT - 1)) || ((col <= h_pos0 - H_HEIGHT + 1) || (col >= h_pos0 + H_HEIGHT - 1))) begin
			o_VGA_R  = 8'd0;
			o_VGA_G  = 8'hFF;
			o_VGA_B  = 8'd0;
		end
	end

		// Draw cursor
	if ((row >= v_pos1 - 1) && (row <= v_pos1 + 1) && (col >= h_pos1 - 1) && (col <= h_pos1 + 1)) begin
			o_VGA_R  = 8'd0;
			o_VGA_G  = 8'h00;
			o_VGA_B  = 8'hFF;
	end

	if ((col == {3'b0, rand_o[0]}) || raw_VGA_Blob) begin
		o_VGA_R  = 8'd0;
		o_VGA_G  = 8'h00;
		o_VGA_B  = 8'h0;
	 end
end



	// State machine for frame sync
always @(*) begin
	vsyncflag_c = vsyncflag; 
	state_c     = state;
	
	case (state)
	
		INIT: begin
			if (~VGA_VS) begin
				vsyncflag_c = 1'b1;
				state_c     = VSYNC;
			end
		end
		
		VSYNC: begin
			vsyncflag_c = 1'b0;
			if (VGA_VS) begin
				state_c = INIT;
			end
		end
	endcase
	
	if(~reset_n) begin
		vsyncflag_c = 1'b0;
		state_c     = INIT;
	end
end

always @(*) begin

	v_pos0_c = v_pos0;
	h_pos0_c = h_pos0;
	v_pos1_c = v_pos1;
	h_pos1_c = h_pos1;
	noise_c = {(noise[9] ^ noise[8] ^ noise [5] ^ noise[0]),noise[9:1]};

	if(vsyncflag) begin

	   // Update position
	   if(~cursor_select) begin
			if (cursor_speed[0]) begin
				h_pos0_c = h_pos0 + 9'd1;
			end else if (cursor_speed[3]) begin
				h_pos0_c = h_pos0 - 9'd1;
			end
			if (cursor_speed[2]) begin
				v_pos0_c = v_pos0 + 9'd1;
			end else if (cursor_speed[1]) begin
				v_pos0_c = v_pos0 - 9'd1;
			end
	   end else begin
			if (cursor_speed[0]) begin
				h_pos1_c = h_pos1 + 9'd1;
			end else if (cursor_speed[3]) begin
				h_pos1_c = h_pos1 - 9'd1;
			end
			if (cursor_speed[2]) begin
				v_pos1_c = v_pos1 + 9'd1;
			end else if (cursor_speed[1]) begin
				v_pos1_c = v_pos1 - 9'd1;
			end
	   end

	   if(~cursor_select) begin
			// Collisions
			if (cursor_speed[1]) begin
				if (v_pos0 <= 9'd5) begin
					v_pos0_c = 9'd5;
				end
			end else if (cursor_speed[2]) begin
				if (v_pos0 >= 9'd477 - 9'd7) begin
					v_pos0_c = 9'd472;
				end
			end

			if (cursor_speed[3]) begin
				if (h_pos0 <= 10'd6) begin
					h_pos0_c = 10'd6;
				end
			end else if (cursor_speed[0]) begin
				if (h_pos0 >= 10'd617 - 10'd8) begin
					h_pos0_c = 10'd609;
				end
			end
	   end else begin
			if (cursor_speed[1]) begin
				if (v_pos1 <= 9'd2) begin
					v_pos1_c = 9'd2;
				end
			end else if(cursor_speed[2]) begin
				if (v_pos1 >= 9'd477 - 9'd2) begin
					v_pos1_c = 9'd475;
				end
			end
			if (cursor_speed[3]) begin
				if (h_pos1 <= 10'd2) begin
					h_pos1_c = 10'd2;
				end
			end else if(cursor_speed[0]) begin
				if (h_pos1 >= 10'd617 - 10'd5) begin
					h_pos1_c = 10'd611;
				end
			end
	   end
	end

	if(~reset_n) begin
	   v_pos0_c = 9'd240;
	   h_pos0_c = 10'd320;
	   v_pos1_c = 9'd270;
	   h_pos1_c = 10'd380;
	   noise_c  = 10'b1100101010;
	end
 end

always @(posedge clk) begin
	vsyncflag <= vsyncflag_c;
	state     <= state_c;
	v_pos0    <= v_pos0_c;
	v_pos1    <= v_pos1_c;
	h_pos0    <= h_pos0_c;
	h_pos1    <= h_pos1_c;
	noise     <= noise_c;
end

   // Random Number Generator (LFSR)
RNG  RNG_inst (
    .clk(clk),
    .frame(vsyncflag),
    .rst(~reset_n),
    .seed_i(10'b1010010101),
    .rand_o(rand_o[0])
  );

   // Random Number Generator (LFSR)
  RNG  RNG_inst1 (
   .clk(clk),
   .frame(vsyncflag),
   .rst(~reset_n),
   .seed_i(10'b0100100101),
   .rand_o(rand_o[1])
 );

   // Random Number Generator (LFSR)
 RNG  RNG_inst2 (
   .clk(clk),
   .frame(vsyncflag),
   .rst(~reset_n),
   .seed_i(10'b01101001101),
   .rand_o(rand_o[2])
 );

endmodule
