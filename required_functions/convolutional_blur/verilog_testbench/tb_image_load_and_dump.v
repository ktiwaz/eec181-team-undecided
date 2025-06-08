module tb_image_load_and_dump;

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

  wire [7:0] oVGA_R;
  wire [7:0] oVGA_G;
  wire [7:0] oVGA_B;

  wire valid;

  wire [7:0] red_out, green_out, blue_out;
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

  // reg signed [8:0] kernel [0:10][0:10];
  

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

  conv_kernel # (
    .LINE_WIDTH(WIDTH),
    .PIXEL_DEPTH(8)
  )
  conv_kernel_inst (
    .clk(clk),
    .vs_ni(valid),
    .hs_ni(1'b0),
    .blank_ni(1'b0),
    .input_R(VGA_R),
    .input_G(VGA_G),
    .input_B(VGA_B),
    .vs_no(out_valid),
    .hs_no(),
    .blank_no(),
    .output_R(red_out),
    .output_G(green_out),
    .output_B(blue_out)
  );

  RGB_Process  RGB_Process_inst (
    .raw_VGA_R(VGA_R),
    .raw_VGA_G(VGA_G),
    .raw_VGA_B(VGA_B),
    .row(row),
    .col(col),
    .filter_SW(6'b000000),
    .o_VGA_R(oVGA_R),
    .o_VGA_G(oVGA_G),
    .o_VGA_B(oVGA_B)
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
    .valid(out_valid)
  );

  // Clock generation
  always begin
    #5 clk = ~clk; // 100 MHz clock, adjust timing as needed
  end



  // Testbench logic
  initial begin
    // Dump signals to VCD file
    $dumpfile("image_load_dump.vcd"); // Specify VCD file name
    $dumpvars(0, tb_image_load_and_dump);    // Dump all signals in this module
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

  // initial begin
  //   kernel[0][0] = 9'd5;   kernel[0][1] = 9'd15;  kernel[0][2] = 9'd30;  kernel[0][3] = 9'd40;  kernel[0][4] = 9'd45;
  //   kernel[0][5] = 9'd50;  kernel[0][6] = 9'd45;  kernel[0][7] = 9'd40;  kernel[0][8] = 9'd30;  kernel[0][9] = 9'd15; kernel[0][10] = 9'd5;
  
  //   kernel[1][0] = 9'd15;  kernel[1][1] = 9'd35;  kernel[1][2] = 9'd50;  kernel[1][3] = 9'd60;  kernel[1][4] = 9'd65;
  //   kernel[1][5] = 9'd70;  kernel[1][6] = 9'd65;  kernel[1][7] = 9'd60;  kernel[1][8] = 9'd50;  kernel[1][9] = 9'd35; kernel[1][10] = 9'd15;
  
  //   kernel[2][0] = 9'd30;  kernel[2][1] = 9'd50;  kernel[2][2] = 9'd65;  kernel[2][3] = 9'd80;  kernel[2][4] = 9'd90;
  //   kernel[2][5] = 9'd90;  kernel[2][6] = 9'd90;  kernel[2][7] = 9'd80;  kernel[2][8] = 9'd65;  kernel[2][9] = 9'd50; kernel[2][10] = 9'd30;
  
  //   kernel[3][0] = 9'd40;  kernel[3][1] = 9'd60;  kernel[3][2] = 9'd80;  kernel[3][3] = 9'd95;  kernel[3][4] = 9'd110;
  //   kernel[3][5] = 9'd115; kernel[3][6] = 9'd110; kernel[3][7] = 9'd95;  kernel[3][8] = 9'd80;  kernel[3][9] = 9'd60; kernel[3][10] = 9'd40;
  
  //   kernel[4][0] = 9'd45;  kernel[4][1] = 9'd65;  kernel[4][2] = 9'd90;  kernel[4][3] = 9'd110; kernel[4][4] = 9'd125;
  //   kernel[4][5] = 9'd135; kernel[4][6] = 9'd125; kernel[4][7] = 9'd110; kernel[4][8] = 9'd90;  kernel[4][9] = 9'd65; kernel[4][10] = 9'd45;
  
  //   kernel[5][0] = 9'd50;  kernel[5][1] = 9'd70;  kernel[5][2] = 9'd90;  kernel[5][3] = 9'd115; kernel[5][4] = 9'd135;
  //   kernel[5][5] = 9'd160; kernel[5][6] = 9'd135; kernel[5][7] = 9'd115; kernel[5][8] = 9'd90;  kernel[5][9] = 9'd70; kernel[5][10] = 9'd50;
  
  //   kernel[6][0] = 9'd45;  kernel[6][1] = 9'd65;  kernel[6][2] = 9'd90;  kernel[6][3] = 9'd110; kernel[6][4] = 9'd125;
  //   kernel[6][5] = 9'd135; kernel[6][6] = 9'd125; kernel[6][7] = 9'd110; kernel[6][8] = 9'd90;  kernel[6][9] = 9'd65; kernel[6][10] = 9'd45;
  
  //   kernel[7][0] = 9'd40;  kernel[7][1] = 9'd60;  kernel[7][2] = 9'd80;  kernel[7][3] = 9'd95;  kernel[7][4] = 9'd110;
  //   kernel[7][5] = 9'd115; kernel[7][6] = 9'd110; kernel[7][7] = 9'd95;  kernel[7][8] = 9'd80;  kernel[7][9] = 9'd60; kernel[7][10] = 9'd40;
  
  //   kernel[8][0] = 9'd30;  kernel[8][1] = 9'd50;  kernel[8][2] = 9'd65;  kernel[8][3] = 9'd80;  kernel[8][4] = 9'd90;
  //   kernel[8][5] = 9'd90;  kernel[8][6] = 9'd90;  kernel[8][7] = 9'd80;  kernel[8][8] = 9'd65;  kernel[8][9] = 9'd50; kernel[8][10] = 9'd30;
  
  //   kernel[9][0] = 9'd15;  kernel[9][1] = 9'd35;  kernel[9][2] = 9'd50;  kernel[9][3] = 9'd60;  kernel[9][4] = 9'd65;
  //   kernel[9][5] = 9'd70;  kernel[9][6] = 9'd65;  kernel[9][7] = 9'd60;  kernel[9][8] = 9'd50;  kernel[9][9] = 9'd35; kernel[9][10] = 9'd15;
  
  //   kernel[10][0] = 9'd5;  kernel[10][1] = 9'd15; kernel[10][2] = 9'd30; kernel[10][3] = 9'd40; kernel[10][4] = 9'd45;
  //   kernel[10][5] = 9'd50; kernel[10][6] = 9'd45; kernel[10][7] = 9'd40; kernel[10][8] = 9'd30; kernel[10][9] = 9'd15; kernel[10][10] = 9'd5;
  // end
  
  

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
