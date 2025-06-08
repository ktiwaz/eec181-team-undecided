module denoise #(
    parameter LINE_WIDTH = 640,
    parameter PIXEL_DEPTH = 8
) (

    input clk,
    input vs_ni,
    input hs_ni,
    input blank_ni,
    input color_i,
    input en_i,
    input [3:0] threshold_sw,

    input [12:0] row,
    input [12:0] col,

    input [PIXEL_DEPTH-1:0] input_R,
    input [PIXEL_DEPTH-1:0] input_G,
    input [PIXEL_DEPTH-1:0] input_B,
    output vs_no,
    output hs_no,
    output blank_no,
    output reg left_paddle,
    output reg right_paddle,
	 output [12:0] row_o,
    output [12:0] col_o,
	 output [PIXEL_DEPTH-1:0] output_R,
    output [PIXEL_DEPTH-1:0] output_G,
    output [PIXEL_DEPTH-1:0] output_B
);

localparam SIZE = 5;
localparam CENTER = SIZE / 2;
localparam LINE_BUFFER_BUS_SIZE = 3*PIXEL_DEPTH + 4 + 26; // Extra bits for vs, hs, blank, color

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire in_img [0:SIZE-1][0:SIZE-1];
wire out_img;

assign output_R = window[CENTER][CENTER][23:16];
assign output_G = window[CENTER][CENTER][15:8];
assign output_B = window[CENTER][CENTER][7:0];

assign row_o = window[CENTER][CENTER][LINE_BUFFER_BUS_SIZE-5:LINE_BUFFER_BUS_SIZE-17];
assign col_o = window[CENTER][CENTER][LINE_BUFFER_BUS_SIZE-18:LINE_BUFFER_BUS_SIZE-30];

genvar iii, jjj;

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

  sliding_window # (
    .NUMBER_OF_LINES(SIZE),
    .WIDTH(LINE_WIDTH),
    .BUS_SIZE(LINE_BUFFER_BUS_SIZE)
  )
  sliding_window_inst (
    .clock(clk),
    .EN(en_i),
    .data({color_i, vs_ni, hs_ni, blank_ni, row, col, input_R, input_G, input_B}),
    .dataout(window)
  );

  majority_filter # (
    .N_SIZE(SIZE),
    .COLORS(1)
  )
  majority_filter_inst (
    .in_img(in_img),
    .out_img(out_img),
    .n_threshold(threshold_sw)
  );
  
  always @(*) begin
		left_paddle = out_img;
		right_paddle = out_img;
		if (col_o <= 317) begin
			right_paddle = 1'b0;
		end
		if (col_o > 309) begin
			left_paddle = 1'b0;
		end
  end
  
endmodule
