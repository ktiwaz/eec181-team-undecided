
module tb_line_buffer;

  // Parameters
  localparam  WIDTH = 640;
  localparam  PIXEL_WIDTH = 8;
  localparam  COL_WIDTH = 10;

  //Ports
  reg clk = 0;
  reg [COL_WIDTH-1:0] col = 0;
  reg [PIXEL_WIDTH-1:0] pixel_in = 0;
  wire [PIXEL_WIDTH-1:0] pixel_out;
  reg line_flag = 0;

  line_buffer # (
    .WIDTH(WIDTH),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .COL_WIDTH(COL_WIDTH)
  )
  line_buffer_inst (
    .clk(clk),
    .col(col),
    .pixel_in(pixel_in),
    .pixel_out(pixel_out)
  );

always #5  clk = ! clk;

integer i;

initial begin
  #20;
  for(i = 0; i < 640*480; i=i+1) begin
    @(posedge clk);
    pixel_in = pixel_in + 1'b1;
    if (col == WIDTH-1) begin
      col = 0;
      line_flag = 1'b1;
    end else begin
      col = col + 1'b1;
      line_flag = 1'b0;
    end
  end
  #100;
  $finish();
end

initial begin
    // Dump waveform data
    $dumpfile("tb_line_buffer.vcd");
    $dumpvars(0, tb_line_buffer);
end

endmodule