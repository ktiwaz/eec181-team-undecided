module image_process_pipeline #(
   parameter LINES = 640,
   parameter PIXEL_DEPTH = 8
)(
	input clk, reset_n,
   input [PIXEL_DEPTH-1:0] raw_VGA_R, raw_VGA_G, raw_VGA_B,
	input [12:0] row, col,
   input [4:0] thresh,
   input [1:0] mode,
   input valid_i,
	output out_image,
   output reg [PIXEL_DEPTH-1:0] VGA_R, VGA_G, VGA_B,
   output reg valid_o
);

wire [7:0] oVGA_R, oVGA_G, oVGA_B;
wire o_color;

RGB_Process p1 (
   .raw_VGA_R (raw_VGA_R),
   .raw_VGA_G (raw_VGA_G),
   .raw_VGA_B (raw_VGA_B),
   .row       (row),
   .col       (col),
   .o_VGA_R   (oVGA_R),
   .o_VGA_G   (oVGA_G),
   .o_VGA_B   (oVGA_B),
   .o_color   (o_color)
);


/* Input Signals
//--- VGA interface signals ---
assign VGA_CLK    = MIPI_PIXEL_CLK;           // GPIO clk
assign VGA_SYNC_N = 1'b0;

// orequest signals when an output from the camera is needed
assign orequest = ((x_count > 13'd0160 && x_count < 13'd0800 ) &&
                  ( y_count > 13'd0045 && y_count < 13'd0525));

// this blanking signal is active low
assign vga_blank_ni = ~((x_count < 13'd0160 ) || ( y_count < 13'd0045 ));

// generate the horizontal and vertical sync signals
always @(*) begin
   if ((x_count >= 13'd0002 ) && ( x_count <= 13'd0097))
      vga_hs_ni = 1'b0;
   else
      vga_hs_ni = 1'b1;

   if ((y_count >= 13'd0013 ) && ( y_count <= 13'd0014))
      vga_vs_ni = 1'b0;
   else
      vga_vs_ni = 1'b1;
end

// calculate col and row as an offset from the x and y counter values
assign col = x_count - 13'd0164;
assign row = y_count - 13'd0047;
*/

/*
if col ranges from 0 to 640 in our sim, and row from 0 to 480
x_count ranges from 164 to 800-something
y_count ranges from 47 to 527 or so 
then vga_hs_ni = 1'b1 at all points
vga_vs_ni = 1'b1;
vga_blank_ni = 1'b1
orequest appears to be 1'b1, will further verify later
*/

// start inserting remaining modules here



wire vs_ni, hs_ni, blank_ni, o_request;

assign vs_ni = 1'b1;
assign hs_ni = 1'b1;
assign vga_blank_ni = 1'b1;
assign orequest = 1'b1;



wire [12:0] T, B, L, R;
wire valid_o_conv;
wire [7:0] VGA_R_conv, VGA_G_conv, VGA_B_conv;

conv_kernel_modded # (
    .LINE_WIDTH(LINES),
    .PIXEL_DEPTH(PIXEL_DEPTH)
  )
  conv_kernel_inst (
    .clk          (clk),
	.rstn        (reset_n),
    .en_i         (1'b1),
    .vs_ni        (vs_ni),
    .hs_ni        (hs_ni),
    .blank_ni     (vga_blank_ni),
    .row          (row),
    .col          (col),
    .color_i      (o_color),  // filtering only 
    .filter_en    (1'b1),
    .rect_en      (1'b0),
    .threshold     (thresh),
    .input_R      (oVGA_R),
    .input_G      (oVGA_G),
    .input_B      (oVGA_B),

    // added ports
    .valid_i      (valid_i),
    .valid_o      (valid_o_conv),
    .out_img    (out_image),

    // outputs unused in sim 
    .vs_no        (VGA_VS),
    .hs_no        (VGA_HS),
    .blank_no     (VGA_BLANK_N),

   // used:
    .output_R     (VGA_R_conv),
    .output_G     (VGA_G_conv),
    .output_B     (VGA_B_conv),

    // outputs unused in sim
	 .TO(T),
	 .BO(B),
	 .LO(L),
	 .RO(R)
  );




always @(*) begin

   // color only
   if (mode == 2'b10) begin
      valid_o = valid_i;
      if (o_color == 1'b1) begin
         VGA_R = 8'h0;
         VGA_G = 8'h0;
         VGA_B = 8'h0;
      end else begin
         VGA_R = oVGA_R;
         VGA_G = oVGA_G;
         VGA_B = oVGA_B;
      end
   end

   else if (mode == 2'b11) begin
      valid_o = valid_o_conv;
      VGA_R = VGA_R_conv;
      VGA_G = VGA_G_conv;
      VGA_B = VGA_B_conv;
   end
   
   else begin
      valid_o = valid_o_conv;
      VGA_R = raw_VGA_R;
      VGA_G = raw_VGA_G;
      VGA_B = raw_VGA_B;
   end


end


endmodule