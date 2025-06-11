module image_loader #(
  parameter WIDTH=640,
  parameter HEIGHT=480,
  parameter INDEX_WIDTH = 19
) (
  input clk,
  input reset_n,
  output [7:0] VGA_R,
  output [7:0] VGA_G,
  output [7:0] VGA_B,
  output valid
);
localparam MEM_DEPTH = WIDTH * HEIGHT;

reg [23:0] image_mem [0:MEM_DEPTH-1]; // Each entry is {R[7:0], G[7:0], B[7:0]}
integer file, r, g, b;
integer i;
integer status;


reg [7:0] VGA_R_q;
reg [7:0] VGA_G_q;
reg [7:0] VGA_B_q;
reg valid_q;
reg [INDEX_WIDTH-1:0] index;

assign VGA_R = VGA_R_q;
assign VGA_G = VGA_G_q;
assign VGA_B = VGA_B_q;
assign valid = valid_q;

initial begin
  file = $fopen("verilog_pixels.txt", "r");
  if (file == 0) begin
    $display("Error: Could not open file.");
    $finish;
  end

  for (i = 0; i < MEM_DEPTH; i = i + 1) begin
    status = $fscanf(file, "0x%x, 0x%x, 0x%x\n", r, g, b);
    if (status != 3) begin
      $display("Error reading pixel at index %0d", i);
      $finish;
    end
    image_mem[i] = {r[7:0], g[7:0], b[7:0]};
  end

  $fclose(file);
end

always @(posedge clk) begin
  if (~reset_n) begin
    index <= 0;
  end else begin
    valid_q <= 1'b1;
    VGA_R_q <= image_mem[index][23:16];
    VGA_G_q <= image_mem[index][15:8];
    VGA_B_q <= image_mem[index][7:0];

    if (index == MEM_DEPTH - 1)
      index <= 0;
    else
      index <= index + 1;
  end
end

endmodule
