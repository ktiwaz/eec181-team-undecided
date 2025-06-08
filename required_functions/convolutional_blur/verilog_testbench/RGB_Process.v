module RGB_Process(
    input  [7:0] raw_VGA_R,
    input  [7:0] raw_VGA_G,
    input  [7:0] raw_VGA_B,
    input  [12:0] row,
    input  [12:0] col,
    input  [5:0]  filter_SW,

    output reg [7:0] o_VGA_R,
    output reg [7:0] o_VGA_G,
    output reg [7:0] o_VGA_B
);

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

always @(*) begin
    if (row <= 13'd479 && col < 13'd639) begin // valid VGA range
        o_VGA_R = luminance[7:0]; // Same value for grayscale
        o_VGA_G = luminance[7:0];
        o_VGA_B = luminance[7:0];
    end else begin
        // Out-of-range pixels are black
        o_VGA_R = 8'b00000000;
        o_VGA_G = 8'b00000000;
        o_VGA_B = 8'b00000000;
    end
end

endmodule