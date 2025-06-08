module vector_calculation(
	input               clk,
	input               reset,
	
	input               in_paddle, // from denoiser
	input        [12:0] row,
	input        [12:0] col,
	
	input               V_sync,
	 
	output reg signed [14:0] nx,
	output reg signed [14:0] ny,
	output signed [14:0] lx, 
	output signed [14:0] ly
);

// 4 corner coordinates registers
// internal register for box position, update every clock cycle
reg [12:0] top_y,top_y_c, top_x, top_x_c;
reg [12:0] bot_y ,bot_y_c, bot_x, bot_x_c;
reg [12:0] left_y,left_y_c, left_x, left_x_c;
reg [12:0] right_y,right_y_c, right_x, right_x_c;
// external register for box position, update every v sync signal
reg [12:0] To_y, To_y_c, To_x, To_x_c;
reg [12:0] Bo_y, Bo_y_c, Bo_x, Bo_x_c;
reg [12:0] Lo_y, Lo_y_c, Lo_x, Lo_x_c;
reg [12:0] Ro_y, Ro_y_c, Ro_x, Ro_x_c;

reg first_N,first_N_c; // first color pixel

// Anchor point coordinates
reg [12:0] A_x, A_y, B_x, B_y;

wire signed [13:0] A_xs, A_ys, B_xs, B_ys;

assign A_xs = {1'b0, A_x};
assign A_ys = {1'b0, A_y};
assign B_xs = {1'b0, B_x};
assign B_ys = {1'b0, B_y};

wire signed [14:0] dx, dy;

always @(*) begin
	nx = -dx;
	ny = -dy;
end

assign dx = B_ys - A_ys;
assign dy = A_xs - B_xs;

assign lx = B_xs - A_xs;
assign ly = B_ys - A_ys;

always@(posedge clk)begin
	top_y   <= top_y_c;
	top_x   <= top_x_c;
	bot_y   <= bot_y_c;
	bot_x   <= bot_x_c;
	left_y  <= left_y_c;
	left_x  <= left_x_c;

	right_y <= right_y_c;
	right_x <= right_x_c;
	first_N <= first_N_c;
	
	To_y <= To_y_c;
	Bo_y <= Bo_y_c;
	Lo_y <= Lo_y_c;
	Ro_y <= Ro_y_c;

	To_x <= To_x_c;
	Bo_x <= Bo_x_c;
	Lo_x <= Lo_x_c;
	Ro_x <= Ro_x_c;
end

always@(*) begin
	top_y_c   = top_y;
	bot_y_c   = bot_y;
	left_y_c  = left_y;
	right_y_c = right_y;

	top_x_c   = top_x;
	bot_x_c   = bot_x;
	left_x_c  = left_x;
	right_x_c = right_x;
	
	To_y_c = To_y;
	Bo_y_c = Bo_y;
	Lo_y_c = Lo_y;
	Ro_y_c = Ro_y;

	To_x_c = To_x;
	Bo_x_c = Bo_x;
	Lo_x_c = Lo_x;
	Ro_x_c = Ro_x;
	
	first_N_c = first_N;
	
	if(in_paddle)begin // if the pixel is classified as required color.
		first_N_c = 1'b1;  
		
		if(first_N)begin  // is this the first pixels thats certain color? no then compare the coordinate with the box coordinates
			if (row < top_y) begin
				top_y_c = row;
				top_x_c = col;
			end
				
			if (row > bot_y) begin
				bot_y_c = row;
				bot_x_c = col;
			end
		
			if (col < left_x) begin
				left_x_c = col;
				left_y_c = row;
			end
				
			if (col > right_x) begin
				right_x_c = col;
				right_y_c = row;
			end
		end
		
		else begin  // if this is the first pixel, record the pixel coordinates as the box coordinates
			top_y_c = row;
			bot_y_c = row;
			left_x_c = col;
			right_x_c = col;

			left_y_c = row;
			right_y_c = row;
			top_x_c = col;
			bot_x_c = col;
		end
	end
	
	if	(V_sync) begin // sync per frame, should update the corners captured this cycle, reset the internetal corener register
		top_y_c   = 13'd00;
		bot_y_c   = 13'd00;
		left_y_c  = 13'd00;
		right_y_c = 13'd00;
	
		top_x_c   = 13'd00;
		bot_x_c   = 13'd00;
		left_x_c  = 13'd00;
		right_x_c = 13'd00;
		first_N_c = 1'b0;
		
		To_y_c = top_y;
		Bo_y_c = bot_y;
		Lo_y_c = left_y;
		Ro_y_c = right_y;
	
		To_x_c = top_x;
		Bo_x_c = bot_x;
		Lo_x_c = left_x;
		Ro_x_c = right_x;	
	end
	
	if (~reset) begin
		top_y_c   = 13'd00;
		bot_y_c   = 13'd00;
		left_y_c  = 13'd00;
		right_y_c = 13'd00;
	
		top_x_c   = 13'd00;
		bot_x_c   = 13'd00;
		left_x_c  = 13'd00;
		right_x_c = 13'd00;
		first_N_c = 1'b0;
		
		To_y_c = 13'd00;
		Bo_y_c = 13'd00;
		Lo_y_c = 13'd00;
		Ro_y_c = 13'd00;
	
		To_x_c = 13'd00;
		Bo_x_c = 13'd00;
		Lo_x_c = 13'd00;
		Ro_x_c = 13'd00;
	end
end


// Calculate Anchor points based on paddle orientation
always @(*) begin
	A_x = To_x;
	A_y = To_y;
	B_x = Bo_x;
	B_y = Bo_y;
	if(Lo_y < Ro_y) begin
		A_x = Lo_x;
		A_y = Lo_y;
		B_x = Bo_x;
		B_y = Bo_y;
	end else if(Lo_y > Ro_y) begin
		A_x = To_x;
		A_y = To_y;
		B_x = Lo_x;
		B_y = Lo_y;
	end else if (Lo_y == Ro_y) begin
		A_x = To_x;
		A_y = To_y;
		B_x = Bo_x;
		B_y = Bo_y;
	end
end
endmodule
