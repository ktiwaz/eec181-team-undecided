module conv_kernel #(
    parameter LINE_WIDTH = 640,
    parameter PIXEL_DEPTH = 8
) (

    input clk,
    input vs_ni,
    input hs_ni,
    input blank_ni,

    input [PIXEL_DEPTH-1:0] input_R,
    input [PIXEL_DEPTH-1:0] input_G,
    input [PIXEL_DEPTH-1:0] input_B,
    output vs_no,
    output hs_no,
    output blank_no,
    output reg [PIXEL_DEPTH-1:0] output_R,
    output reg [PIXEL_DEPTH-1:0] output_G,
    output reg [PIXEL_DEPTH-1:0] output_B
);

localparam SIZE = 3;
localparam KERNEL_WIDTH = 4;
localparam LINE_BUFFER_BUS_SIZE = 3*PIXEL_DEPTH + 3; // Extra bits for vs, hs, blank
localparam SUM_WIDTH = KERNEL_WIDTH + PIXEL_DEPTH + $clog2(SIZE*SIZE);
localparam THRESHOLD = 255;

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed[PIXEL_DEPTH:0] window_R [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_G [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_B [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed [KERNEL_WIDTH-1:0] kernel [0:SIZE-1] [0:SIZE-1];

assign kernel[0][0] = 4'sd1; assign kernel[0][1] = 4'sd2; assign kernel[0][2] = 4'sd1;
assign kernel[1][0] = 4'sd2; assign kernel[1][1] = 4'sd4; assign kernel[1][2] = 4'sd2;
assign kernel[2][0] = 4'sd1; assign kernel[2][1] = 4'sd2; assign kernel[2][2] = 4'sd1;

integer i, j;

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

reg signed [SUM_WIDTH-1:0] sum_R, sum_G, sum_B;

wire signed [7:0] sum_R_slice;
wire signed [7:0] sum_G_slice;
wire signed [7:0] sum_B_slice;

assign sum_R_slice = sum_R[11:4];
assign sum_G_slice = sum_G[11:4];
assign sum_B_slice = sum_B[11:4];

// Assign VS, HS, blank based on middle of buffer
assign vs_no = window[1][1][LINE_BUFFER_BUS_SIZE-1]; 
assign hs_no = window[1][1][LINE_BUFFER_BUS_SIZE-2]; 
assign blank_no = window[1][1][LINE_BUFFER_BUS_SIZE-3]; 

sliding_window # (
    .NUMBER_OF_LINES(SIZE),
    .WIDTH(LINE_WIDTH),
    .BUS_SIZE(LINE_BUFFER_BUS_SIZE)
  )
  sliding_window_inst (
    .clock(clk),
    .EN(vs_ni),
    .data({vs_ni, hs_ni, blank_ni, input_R, input_G, input_B}),
    .dataout(window)
  );

  always @(*) begin
    // Initialize sums to 0 for each color channel
    sum_R = 0;
    sum_G = 0;
    sum_B = 0;
    
    // Apply the kernel to the window
    for (i = 0; i < SIZE; i = i + 1) begin
        for (j = 0; j < SIZE; j = j + 1) begin
            // Apply kernel for red channel
            sum_R = sum_R + (window_R[i][j] * kernel[i][j]);
            sum_G = sum_G + (window_G[i][j] * kernel[i][j]);
            sum_B = sum_B + (window_B[i][j] * kernel[i][j]);    
        end
    end

    output_R = sum_R_slice;
    output_G = sum_G_slice;
    output_B = sum_B_slice;

        // if (sum_R_slice > -THRESHOLD && sum_R_slice < 0) begin
        //     output_R = -sum_R_slice;
        // end else if (sum_R_slice > THRESHOLD || sum_R_slice < -THRESHOLD) begin
        //     output_R = 8'hff;
        // end else begin
        //     output_R = sum_R_slice;
        // end

        // if (sum_G_slice > -THRESHOLD && sum_G_slice < 0) begin
        //     output_G = -sum_G_slice;
        // end else if (sum_G_slice > THRESHOLD || sum_G_slice < -THRESHOLD) begin
        //     output_G = 8'hff;
        // end else begin
        //     output_G = sum_G_slice;
        // end

        // if (sum_B_slice > -THRESHOLD && sum_B_slice < 0) begin
        //     output_B = -sum_B_slice;
        // end else if (sum_B_slice > THRESHOLD || sum_B_slice < -THRESHOLD) begin
        //     output_B = 8'hff;
        // end else begin
        //     output_B = sum_B_slice;
        // end
    end

endmodule
