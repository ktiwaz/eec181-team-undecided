module line_buffer #(
  parameter WIDTH = 640,           // Number of pixels per line
  parameter PIXEL_WIDTH = 8,        // Bits per pixel
  parameter COL_WIDTH = 10
)(
  input                    clk,
  input  [COL_WIDTH-1:0]   col,    // asserted when pixel_in is valid
  input  [PIXEL_WIDTH-1:0] pixel_in,     // current input pixel
  output [PIXEL_WIDTH-1:0] pixel_out     // pixel delayed by one line
);

  // Memory to hold one line of pixels
  reg [PIXEL_WIDTH-1:0] mem [0:WIDTH-1];

  // Write to memory
  always @(posedge clk) begin
    if (col < WIDTH) begin
      mem[col] <= pixel_in;
    end
  end

  // Read from memory: read from the same address you're writing to
  assign pixel_out = mem[col];

endmodule
