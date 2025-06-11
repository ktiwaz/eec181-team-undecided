module tb_hsv_image_filter;

  // Testbench parameters
  parameter WIDTH = 640;
  parameter HEIGHT = 480;
  parameter MEM_DEPTH = WIDTH * HEIGHT;
  parameter INDEX_WIDTH = 19;

  // Testbench signals
  reg clk;
  reg reset_n;
  reg [12:0] row = 0;
  reg [12:0] col = 0;
  wire [7:0] VGA_R;
  wire [7:0] VGA_G;
  wire [7:0] VGA_B;

  wire valid;

  wire [7:0] red_out, green_out;
  wire [7:0] blue_out;
  wire out_valid;


//   assign out_valid = dataout[0][0][24];

//   wire [11:0] red_sum;
//   wire [11:0] green_sum;
//   wire [11:0] blue_sum;

//   wire [24:0] dataout [0:2][0:2]; // 3D array output
  
// // Red, Green, and Blue channel summations
// assign red_sum = dataout[0][0][23:16] + dataout[1][0][23:16] + dataout[2][0][23:16] +
//                  dataout[0][1][23:16] + dataout[1][1][23:16] + dataout[2][1][23:16] +
//                  dataout[0][2][23:16] + dataout[1][2][23:16] + dataout[2][2][23:16];

// assign green_sum = dataout[0][0][15:8] + dataout[1][0][15:8] + dataout[2][0][15:8] +
//                    dataout[0][1][15:8] + dataout[1][1][15:8] + dataout[2][1][15:8] +
//                    dataout[0][2][15:8] + dataout[1][2][15:8] + dataout[2][2][15:8];

// assign blue_sum = dataout[0][0][7:0] + dataout[1][0][7:0] + dataout[2][0][7:0] +
//                   dataout[0][1][7:0] + dataout[1][1][7:0] + dataout[2][1][7:0] +
//                   dataout[0][2][7:0] + dataout[1][2][7:0] + dataout[2][2][7:0];

// // Output assignments for the Red, Green, and Blue channels
// assign red_out   = (out_valid) ? (red_sum   / 9) : 8'd0;
// assign green_out = (out_valid) ? (green_sum / 9) : 8'd0;
// assign blue_out  = (out_valid) ? (blue_sum  / 9) : 8'd0;

  reg signed [3:0] kernel [0:2][0:2];
  

  // Instantiate the image_loader module
  image_loader #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .INDEX_WIDTH(INDEX_WIDTH)
  ) uut (
    .clk(clk),
    .reset_n(reset_n),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .valid(valid)
  );


  image_process_pipeline #(
    .LINES(640),
    .PIXEL_DEPTH(8)
  )
  pipelineUUT(
    .clk(clk),
    .reset_n(reset_n),
    .raw_VGA_R(VGA_R),
    .raw_VGA_G(VGA_G),
    .raw_VGA_B(VGA_B),
    .valid_i(valid),
    .row(row),
    .col(col),
    .thresh(5'd15),
    .out_image(out_image),
    .mode(2'b11),  // full pipeline sent to output
    .VGA_R(red_out),
    .VGA_G(green_out),
    .VGA_B(blue_out),
    .valid_o(valid_o)
  );



  // Instantiate the image_dumper module
  image_dumper #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .INDEX_WIDTH(INDEX_WIDTH)
  ) uut1 (
    .clk(clk),
    .reset_n(reset_n),
    .VGA_R(red_out),
    .VGA_G(green_out),
    .VGA_B(blue_out),
    .valid(valid_o)
  );

  // Clock generation
  always begin
    #5 clk = ~clk; // 100 MHz clock, adjust timing as needed
  end



  // Testbench logic
  initial begin
    // Dump signals to VCD file
    $dumpfile("image_load_dump.vcd"); // Specify VCD file name
    $dumpvars(0, tb_hsv_image_filter);    // Dump all signals in this module
    // Initialize signals
    clk = 0;
    reset_n = 0;

    // Apply reset
    $display("Applying reset...");
    #15 reset_n = 1; // Deassert reset after 10 time units

    // Simulate enough until dump (finish should be called in dumper)
    #3800000;

    // Finish the simulation (timeout)
    $finish;
  end


  genvar ii, jj;

  // generate
  // for (ii = 0; ii < 3; ii = ii + 1) begin
  //     for (jj = 0; jj < 3; jj = jj + 1) begin
  //         initial $dumpvars(0, kernel[ii][jj]);
  //     end
  // end
  // endgenerate

// Increment row and column
always @(posedge clk) begin
  if (~reset_n) begin
    row <= 0;
    col <= 0;
  end else begin
    if (valid) begin
      if(col == WIDTH - 1) begin
        col <= 0;
        row <= row + 1;
        if(row == HEIGHT - 1) begin
          row <= 0;
        end
      end else begin
        col <= col + 1;
      end
    end
  end
end

endmodule
