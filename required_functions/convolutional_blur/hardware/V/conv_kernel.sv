(* multstyle = "logic" *)
module conv_kernel #(
    parameter LINE_WIDTH = 640,
    parameter PIXEL_DEPTH = 8
) (

    input clk,
    input vs_ni,
    input hs_ni,
    input blank_ni,
    input en_i,
    input blur_en,
    input blur_sel,

    input [PIXEL_DEPTH-1:0] input_R,
    input [PIXEL_DEPTH-1:0] input_G,
    input [PIXEL_DEPTH-1:0] input_B,
    output reg vs_no,
    output reg hs_no,
    output reg blank_no,
    output reg [PIXEL_DEPTH-1:0] output_R,
    output reg [PIXEL_DEPTH-1:0] output_G,
    output reg [PIXEL_DEPTH-1:0] output_B
);

localparam SIZE = 11;
localparam KERNEL_WIDTH = 9;
localparam LINE_BUFFER_BUS_SIZE = 3*PIXEL_DEPTH + 3; // Extra bits for vs, hs, blank
localparam SUM_WIDTH = KERNEL_WIDTH + PIXEL_DEPTH + $clog2(SIZE*SIZE);
localparam THRESHOLD = 255;

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed[PIXEL_DEPTH:0] window_R [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_G [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_B [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed [KERNEL_WIDTH-1:0] kernel [0:SIZE-1] [0:SIZE-1];
wire signed [KERNEL_WIDTH-1:0] kernel_3 [0:2] [0:2];

assign kernel_3[0][0] = 9'sd7;   assign kernel_3[0][1] = 9'sd70;  assign kernel_3[0][2] = 9'sd7;
assign kernel_3[1][0] = 9'sd70;  assign kernel_3[1][1] = 9'sd224; assign kernel_3[1][2] = 9'sd70;
assign kernel_3[2][0] = 9'sd7;   assign kernel_3[2][1] = 9'sd70;  assign kernel_3[2][2] = 9'sd7;


// Assign values to the kernel elements in a compact form
assign kernel[0][0] = 9'd5, kernel[0][1] = 9'd15, kernel[0][2] = 9'd30, kernel[0][3] = 9'd40, kernel[0][4] = 9'd45, kernel[0][5] = 9'd50, kernel[0][6] = 9'd45, kernel[0][7] = 9'd40, kernel[0][8] = 9'd30, kernel[0][9] = 9'd15, kernel[0][10] = 9'd5;
assign kernel[1][0] = 9'd15, kernel[1][1] = 9'd35, kernel[1][2] = 9'd50, kernel[1][3] = 9'd60, kernel[1][4] = 9'd65, kernel[1][5] = 9'd70, kernel[1][6] = 9'd65, kernel[1][7] = 9'd60, kernel[1][8] = 9'd50, kernel[1][9] = 9'd35, kernel[1][10] = 9'd15;
assign kernel[2][0] = 9'd30, kernel[2][1] = 9'd50, kernel[2][2] = 9'd65, kernel[2][3] = 9'd80, kernel[2][4] = 9'd90, kernel[2][5] = 9'd90, kernel[2][6] = 9'd90, kernel[2][7] = 9'd80, kernel[2][8] = 9'd65, kernel[2][9] = 9'd50, kernel[2][10] = 9'd30;
assign kernel[3][0] = 9'd40, kernel[3][1] = 9'd60, kernel[3][2] = 9'd80, kernel[3][3] = 9'd95, kernel[3][4] = 9'd110, kernel[3][5] = 9'd115, kernel[3][6] = 9'd110, kernel[3][7] = 9'd95, kernel[3][8] = 9'd80, kernel[3][9] = 9'd60, kernel[3][10] = 9'd40;
assign kernel[4][0] = 9'd45, kernel[4][1] = 9'd65, kernel[4][2] = 9'd90, kernel[4][3] = 9'd110, kernel[4][4] = 9'd125, kernel[4][5] = 9'd135, kernel[4][6] = 9'd125, kernel[4][7] = 9'd110, kernel[4][8] = 9'd90, kernel[4][9] = 9'd65, kernel[4][10] = 9'd45;
assign kernel[5][0] = 9'd50, kernel[5][1] = 9'd70, kernel[5][2] = 9'd90, kernel[5][3] = 9'd115, kernel[5][4] = 9'd135, kernel[5][5] = 9'd160, kernel[5][6] = 9'd135, kernel[5][7] = 9'd115, kernel[5][8] = 9'd90, kernel[5][9] = 9'd70, kernel[5][10] = 9'd50;
assign kernel[6][0] = 9'd45, kernel[6][1] = 9'd65, kernel[6][2] = 9'd90, kernel[6][3] = 9'd110, kernel[6][4] = 9'd125, kernel[6][5] = 9'd135, kernel[6][6] = 9'd125, kernel[6][7] = 9'd110, kernel[6][8] = 9'd90, kernel[6][9] = 9'd65, kernel[6][10] = 9'd45;
assign kernel[7][0] = 9'd40, kernel[7][1] = 9'd60, kernel[7][2] = 9'd80, kernel[7][3] = 9'd95, kernel[7][4] = 9'd110, kernel[7][5] = 9'd115, kernel[7][6] = 9'd110, kernel[7][7] = 9'd95, kernel[7][8] = 9'd80, kernel[7][9] = 9'd60, kernel[7][10] = 9'd40;
assign kernel[8][0] = 9'd30, kernel[8][1] = 9'd50, kernel[8][2] = 9'd65, kernel[8][3] = 9'd80, kernel[8][4] = 9'd90, kernel[8][5] = 9'd90, kernel[8][6] = 9'd90, kernel[8][7] = 9'd80, kernel[8][8] = 9'd65, kernel[8][9] = 9'd50, kernel[8][10] = 9'd30;
assign kernel[9][0] = 9'd15, kernel[9][1] = 9'd35, kernel[9][2] = 9'd50, kernel[9][3] = 9'd60, kernel[9][4] = 9'd65, kernel[9][5] = 9'd70, kernel[9][6] = 9'd65, kernel[9][7] = 9'd60, kernel[9][8] = 9'd50, kernel[9][9] = 9'd35, kernel[9][10] = 9'd15;
assign kernel[10][0] = 9'd5, kernel[10][1] = 9'd15, kernel[10][2] = 9'd30, kernel[10][3] = 9'd40, kernel[10][4] = 9'd45, kernel[10][5] = 9'd50, kernel[10][6] = 9'd45, kernel[10][7] = 9'd40, kernel[10][8] = 9'd30, kernel[10][9] = 9'd15, kernel[10][10] = 9'd5;

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

wire signed [SUM_WIDTH-11:0] sum_R_slice;
wire signed [SUM_WIDTH-11:0] sum_G_slice;
wire signed [SUM_WIDTH-11:0] sum_B_slice;

assign sum_R_slice = blur_sel ? sum_R[SUM_WIDTH-1:13] : sum_R[SUM_WIDTH-1:9];
assign sum_G_slice = blur_sel ? sum_G[SUM_WIDTH-1:13] : sum_G[SUM_WIDTH-1:9];
assign sum_B_slice = blur_sel ? sum_B[SUM_WIDTH-1:13] : sum_B[SUM_WIDTH-1:9];

sliding_window # (
    .NUMBER_OF_LINES(SIZE),
    .WIDTH(LINE_WIDTH),
    .BUS_SIZE(LINE_BUFFER_BUS_SIZE)
  )
  sliding_window_inst (
    .clock(clk),
    .EN(en_i),
    .data({vs_ni, hs_ni, blank_ni, input_R, input_G, input_B}),
    .dataout(window)
  );

reg signed [SUM_WIDTH-1:0] sum_R_next, sum_G_next, sum_B_next;

always @(*) begin
    sum_R_next = 0;
    sum_G_next = 0;
    sum_B_next = 0;

    if (blur_sel) begin
        // === 11x11 Gaussian Blur ===
        for (i = 0; i < SIZE; i = i + 1) begin
            for (j = 0; j < SIZE; j = j + 1) begin
                sum_R_next = sum_R_next + (window_R[i][j] * kernel[i][j]);
                sum_G_next = sum_G_next + (window_G[i][j] * kernel[i][j]);
                sum_B_next = sum_B_next + (window_B[i][j] * kernel[i][j]);
            end
        end
    end else begin
        // === 3x3 Gaussian Blur centered at [5][5] ===
        sum_R_next =
            window_R[4][4]*kernel_3[0][0] + window_R[4][5]*kernel_3[0][1] + window_R[4][6]*kernel_3[0][2] +
            window_R[5][4]*kernel_3[1][0] + window_R[5][5]*kernel_3[1][1] + window_R[5][6]*kernel_3[1][2] +
            window_R[6][4]*kernel_3[2][0] + window_R[6][5]*kernel_3[2][1] + window_R[6][6]*kernel_3[2][2];

        sum_G_next =
            window_G[4][4]*kernel_3[0][0] + window_G[4][5]*kernel_3[0][1] + window_G[4][6]*kernel_3[0][2] +
            window_G[5][4]*kernel_3[1][0] + window_G[5][5]*kernel_3[1][1] + window_G[5][6]*kernel_3[1][2] +
            window_G[6][4]*kernel_3[2][0] + window_G[6][5]*kernel_3[2][1] + window_G[6][6]*kernel_3[2][2];

        sum_B_next =
            window_B[4][4]*kernel_3[0][0] + window_B[4][5]*kernel_3[0][1] + window_B[4][6]*kernel_3[0][2] +
            window_B[5][4]*kernel_3[1][0] + window_B[5][5]*kernel_3[1][1] + window_B[5][6]*kernel_3[1][2] +
            window_B[6][4]*kernel_3[2][0] + window_B[6][5]*kernel_3[2][1] + window_B[6][6]*kernel_3[2][2];
    end
end

always @(posedge clk) begin
    sum_R <= sum_R_next;
    sum_G <= sum_G_next;
    sum_B <= sum_B_next;
end


always @(posedge clk) begin
    if (blur_en) begin
    if (sum_R_slice > -THRESHOLD && sum_R_slice < 0) begin
        output_R <= -sum_R_slice;
    end else if (sum_R_slice > THRESHOLD || sum_R_slice < -THRESHOLD) begin
        output_R <= 8'hff;
    end else begin
        output_R <= sum_R_slice;
    end

    if (sum_G_slice > -THRESHOLD && sum_G_slice < 0) begin
        output_G <= -sum_G_slice;
    end else if (sum_G_slice > THRESHOLD || sum_G_slice < -THRESHOLD) begin
        output_G <= 8'hff;
    end else begin
        output_G <= sum_G_slice;
    end

    if (sum_B_slice > -THRESHOLD && sum_B_slice < 0) begin
        output_B <= -sum_B_slice;
    end else if (sum_B_slice > THRESHOLD || sum_B_slice < -THRESHOLD) begin
        output_B <= 8'hff;
    end else begin
        output_B <= sum_B_slice;
    end
    end else begin
        output_R <= window_R[5][5][7:0];
        output_G <= window_G[5][5][7:0];
        output_B <= window_B[5][5][7:0];
    end
end

reg vs_d1, vs_d2;
reg hs_d1, hs_d2;
reg blank_d1, blank_d2;

always @(posedge clk) begin
    // Tap from window center
    vs_d1 <= window[5][5][LINE_BUFFER_BUS_SIZE-1];
    hs_d1 <= window[5][5][LINE_BUFFER_BUS_SIZE-2];
    blank_d1 <= window[5][5][LINE_BUFFER_BUS_SIZE-3];

    // 2nd stage
    vs_d2 <= vs_d1;
    hs_d2 <= hs_d1;
    blank_d2 <= blank_d1;

    // Assign to outputs
    vs_no <= vs_d2;
    hs_no <= hs_d2;
    blank_no <= blank_d2;
end
endmodule
