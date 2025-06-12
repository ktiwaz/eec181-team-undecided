module conv_kernel_modded #(
    parameter LINE_WIDTH = 640,
    parameter PIXEL_DEPTH = 8
) (

    input clk,
	 input rstn,
    input vs_ni,
    input hs_ni,
    input blank_ni,
    input color_i,
    input en_i,
    input filter_en,
    input rect_en,
    input [4:0] threshold,

    input [12:0] row,
    input [12:0] col,

    input valid_i,

    input [PIXEL_DEPTH-1:0] input_R,
    input [PIXEL_DEPTH-1:0] input_G,
    input [PIXEL_DEPTH-1:0] input_B,
    output vs_no,
    output hs_no,
    output blank_no,
    output reg [PIXEL_DEPTH-1:0] output_R,
    output reg [PIXEL_DEPTH-1:0] output_G,
    output reg [PIXEL_DEPTH-1:0] output_B,
	 
	 output [12:0] TO,
	 output [12:0] BO,
	 output [12:0] LO,
	 output [12:0] RO,

   output out_img,
   output valid_o
);

localparam SIZE = 5;
localparam CENTER = SIZE / 2;
localparam LINE_BUFFER_BUS_SIZE = 3*PIXEL_DEPTH + 5 + 26; // Extra bits for vs, hs, blank, color, valid_i, +row & col

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed[PIXEL_DEPTH:0] window_R [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_G [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_B [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

genvar iii, jjj;

// Manual sign extension
generate
    for(iii = 0; iii < SIZE; iii++) begin : window_x
        for(jjj=0; jjj < SIZE; jjj++) begin : window_y
            assign window_R[iii][jjj] = {1'b0, window[iii][jjj][3*PIXEL_DEPTH-1:2*PIXEL_DEPTH]};
            assign window_G[iii][jjj] = {1'b0, window[iii][jjj][2*PIXEL_DEPTH-1:PIXEL_DEPTH]};
            assign window_B[iii][jjj] = {1'b0, window[iii][jjj][PIXEL_DEPTH-1:0]};
        end
    end
endgenerate

wire in_img [0:SIZE-1][0:SIZE-1];
//wire out_img;
generate
    for (iii = 0; iii < SIZE; iii = iii + 1) begin : row_loop
        for (jjj = 0; jjj < SIZE; jjj = jjj + 1) begin : col_loop
            assign in_img[iii][jjj] = window[iii][jjj][LINE_BUFFER_BUS_SIZE-1];
        end
    end
endgenerate

// Assign VS, HS, blank based on middle of buffer
assign vs_no = window[CENTER][CENTER][LINE_BUFFER_BUS_SIZE-2]; 
assign hs_no = window[CENTER][CENTER][LINE_BUFFER_BUS_SIZE-3]; 
assign blank_no = window[CENTER][CENTER][LINE_BUFFER_BUS_SIZE-4]; 
assign valid_o = window[CENTER][CENTER][LINE_BUFFER_BUS_SIZE-5];

/* Added for Sim */
wire [7:0] r_o, g_o, b_o;
assign r_o = window[CENTER][CENTER][3*PIXEL_DEPTH-1:2*PIXEL_DEPTH];
assign g_o = window[CENTER][CENTER][2*PIXEL_DEPTH-1:1*PIXEL_DEPTH];
assign b_o = window[CENTER][CENTER][PIXEL_DEPTH-1:0];
/*      */

reg sync, sync_c;
reg state, nextstate;

localparam WAIT = 1'b0;
localparam SYNC = 1'b1;



  sliding_window # (
    .NUMBER_OF_LINES(SIZE),
    .WIDTH(LINE_WIDTH),
    .BUS_SIZE(LINE_BUFFER_BUS_SIZE)
  )
  sliding_window_inst (
    .clock(clk),
    .EN(en_i),
    .data({color_i, vs_ni, hs_ni, blank_ni, valid_i, row, col, input_R, input_G, input_B}), // valid_i added for sim
    .dataout(window)
  );

  denoise # (
    .N_SIZE(SIZE),
    .COLORS(1)
  )
  denoise_inst (
    .in_img(in_img),
    .out_img(out_img),
    .n_threshold(threshold)
  );
  
  
always @(posedge clk) begin
	sync <= sync_c;
	state <= nextstate;
end

always @(*) begin
	sync_c = sync; 
	nextstate = state;
	
	case (state)
		WAIT: begin
			if (~(window[CENTER][CENTER][LINE_BUFFER_BUS_SIZE-2])) begin
				sync_c = 1'b1;
				nextstate = SYNC;
			end
		end
		
		SYNC: begin
			sync_c = 1'b0;
			if (window[CENTER][CENTER][LINE_BUFFER_BUS_SIZE-2]) begin
				nextstate = WAIT;
			end
		end
	endcase
	
	if(~rstn) begin
		sync_c = 1'b0;
		nextstate = WAIT;
	end
end

  wire [12:0] Col,Row;
  assign Row = window[CENTER][CENTER][49:37];
  assign Col = window[CENTER][CENTER][36:24];

  wire [12:0] T,B,L,R;
  wire in_rect_1, in_rect_2;

  assign TO = T;
  assign BO = B;
  assign LO = L;
  assign RO = R;


assign in_rect_1 = 1'b0; // replace if you want to sim with the box
assign in_rect_2 = 1'b0;

  always @(*) begin
    if(filter_en) begin
        if(out_img == 1'b1) begin
            output_R = 8'h00;
            output_G = 8'h00;
            output_B = 8'h00;
        end else begin
            output_R = r_o;
            output_G = g_o;
            output_B = b_o;
        end
    end 
		  
    else begin
        output_R = window_R[CENTER][CENTER][7:0];
        output_G = window_G[CENTER][CENTER][7:0];
        output_B = window_B[CENTER][CENTER][7:0];
    end
    
  end
endmodule
