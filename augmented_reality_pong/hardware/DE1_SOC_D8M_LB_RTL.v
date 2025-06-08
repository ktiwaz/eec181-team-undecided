//=============================================================================
// This module is the top-level template module for hardware to control a
// camera and VGA video interface.
// 
// 2022/03/02  Written [Ziyuan Dong]
// 2022/05/03  Added HEX ports; Added LED, KEY, SW and HEX logic [Ziyuan Dong]
//=============================================================================

module DE1_SOC_D8M_LB_RTL (

//--- 50 MHz clock from DE1-SoC board
input          CLOCK_50,

//--- 10 Switches
input    [9:0] SW,

//--- 4 Push buttons
input    [3:0] KEY,

//--- 10 LEDs
output   [9:0] LEDR,

//--- 6 7-segment hexadecimal displays
output   [7:0] HEX0,                 // seven segment digit 0
output   [7:0] HEX1,                 // seven segment digit 1
output   [7:0] HEX2,                 // seven segment digit 2
output   [7:0] HEX3,                 // seven segment digit 3
output   [7:0] HEX4,                 // seven segment digit 4
output   [7:0] HEX5,                 // seven segment digit 5

//--- VGA    
output         VGA_BLANK_N,
output  [7:0]  VGA_B,
output         VGA_CLK,              // 25 MHz derived from MIPI_PIXEL_CLK
output  [7:0]  VGA_G,
output     VGA_HS,
output  [7:0]  VGA_R,
output         VGA_SYNC_N,
output     VGA_VS,

//--- GPIO_1, GPIO_1 connect to D8M-GPIO 
inout          CAMERA_I2C_SCL,
inout          CAMERA_I2C_SDA,
output         CAMERA_PWDN_n,
output         MIPI_CS_n,
inout          MIPI_I2C_SCL,
inout          MIPI_I2C_SDA,
output         MIPI_MCLK,            // unknown use
input          MIPI_PIXEL_CLK,       // 25 MHz clock from camera
input   [9:0]  MIPI_PIXEL_D,
input          MIPI_PIXEL_HS,   
input          MIPI_PIXEL_VS,
output         MIPI_REFCLK,          // 20 MHz from video_pll.v
output         MIPI_RESET_n
);

//=============================================================================
// reg and wire declarations
//=============================================================================
wire           orequest;
wire    [7:0]  raw_VGA_R;
wire    [7:0]  raw_VGA_G;
wire    [7:0]  raw_VGA_B;
wire           VGA_CLK_25M;
wire           RESET_N; 
wire    [7:0]  sCCD_R;
wire    [7:0]  sCCD_G;
wire    [7:0]  sCCD_B; 
wire   [12:0]  x_count,col; 
wire   [12:0]  y_count,row; 
wire           I2C_RELEASE ;  
wire           CAMERA_I2C_SCL_MIPI; 
wire           CAMERA_I2C_SCL_AF;
wire           CAMERA_MIPI_RELAESE;
wire           MIPI_BRIDGE_RELEASE;

wire           LUT_MIPI_PIXEL_HS;
wire           LUT_MIPI_PIXEL_VS;
wire    [9:0]  LUT_MIPI_PIXEL_D;

reg  vga_vs_ni, vga_hs_ni;
wire vga_blank_ni;

//=======================================================
// Main body of code
//=======================================================

assign  LUT_MIPI_PIXEL_HS = MIPI_PIXEL_HS;
assign  LUT_MIPI_PIXEL_VS = MIPI_PIXEL_VS;
assign  LUT_MIPI_PIXEL_D  = MIPI_PIXEL_D ;

assign RESET_N= ~SW[0]; 

assign MIPI_RESET_n   = RESET_N;
assign CAMERA_PWDN_n  = RESET_N; 
assign MIPI_CS_n      = 1'b0; 


//------ MIPI BRIDGE  I2C SETTING--------------- 
MIPI_BRIDGE_CAMERA_Config cfin(
.RESET_N           ( RESET_N ), 
.CLK_50            ( CLOCK_50), 
.MIPI_I2C_SCL      ( MIPI_I2C_SCL ), 
.MIPI_I2C_SDA      ( MIPI_I2C_SDA ), 
.MIPI_I2C_RELEASE  ( MIPI_BRIDGE_RELEASE ),
.CAMERA_I2C_SCL    ( CAMERA_I2C_SCL ),
.CAMERA_I2C_SDA    ( CAMERA_I2C_SDA ),
.CAMERA_I2C_RELAESE( CAMERA_MIPI_RELAESE )
);

//-- Video PLL --- 
video_pll MIPI_clk(
.refclk   ( CLOCK_50 ),                    // 50MHz clock 
.rst      ( 1'b0 ),     
.outclk_0 ( MIPI_REFCLK )                  // 20MHz clock
);

//--- D8M RAWDATA to RGB ---
D8M_SET   ccd (
.RESET_SYS_N  ( RESET_N ),
.CLOCK_50     ( CLOCK_50 ),
.CCD_DATA     ( LUT_MIPI_PIXEL_D [9:0]),
.CCD_FVAL     ( LUT_MIPI_PIXEL_VS ),       // 60HZ
.CCD_LVAL     ( LUT_MIPI_PIXEL_HS ),        
.CCD_PIXCLK   ( MIPI_PIXEL_CLK),           // 25MHZ from camera
.READ_EN      (orequest),
.VGA_HS       ( VGA_HS ),
.VGA_VS       ( VGA_VS ),
.X_Cont       ( x_count),
.Y_Cont       ( y_count), 
.sCCD_R       ( raw_VGA_R ),
.sCCD_G       ( raw_VGA_G ),
.sCCD_B       ( raw_VGA_B )
);


// HSV filter stage
wire    [7:0]  post_filter_R_c;
wire    [7:0]  post_filter_G_c;
wire    [7:0]  post_filter_B_c;

reg    [7:0]  post_filter_R;
reg    [7:0]  post_filter_G;
reg    [7:0]  post_filter_B;

reg   [12:0]  post_filter_col; 
reg   [12:0]  post_filter_row;

reg post_filter_vs;
reg post_filter_hs;
reg post_filter_blank;

wire o_color_c;
reg  o_color;

//--- Processes the raw RGB pixel data
HSV_filter p1 (
.raw_VGA_R (raw_VGA_R),
.raw_VGA_G (raw_VGA_G),
.raw_VGA_B (raw_VGA_B),
.row       (row),
.col       (col),
.o_VGA_R   (post_filter_R_c),
.o_VGA_G   (post_filter_G_c),
.o_VGA_B   (post_filter_B_c),
.o_color   (o_color_c)
);

// Denoise Stage

// Carry over signals
wire    [7:0]  post_denoise_R_c;
wire    [7:0]  post_denoise_G_c;
wire    [7:0]  post_denoise_B_c;

reg    [7:0]  post_denoise_R;
reg    [7:0]  post_denoise_G;
reg    [7:0]  post_denoise_B;

wire post_denoise_vs_c;
wire post_denoise_hs_c;
wire post_denoise_blank_c;

reg post_denoise_vs;
reg post_denoise_hs;
reg post_denoise_blank;

// New signals
wire in_left_paddle_c;
wire in_right_paddle_c;
wire   [12:0]  post_denoise_col_c; 
wire   [12:0]  post_denoise_row_c;

reg in_left_paddle;
reg in_right_paddle;

reg   [12:0]  post_denoise_col; 
reg   [12:0]  post_denoise_row;

denoise # (
 .LINE_WIDTH(792),
 .PIXEL_DEPTH(8)
)
denoise_inst (
 .clk(VGA_CLK),
 .vs_ni(post_filter_vs),
 .hs_ni(post_filter_hs),
 .blank_ni(post_filter_blank),
 .color_i(o_color),
 .en_i(1'b1),
 .threshold_sw(SW[9:6]),
 .row(post_filter_row),
 .col(post_filter_col),
 .input_R(post_filter_R),
 .input_G(post_filter_G),
 .input_B(post_filter_B),
 .vs_no(post_denoise_vs_c),
 .hs_no(post_denoise_hs_c),
 .blank_no(post_denoise_blank_c),
 .left_paddle(in_left_paddle_c),
 .right_paddle(in_right_paddle_c),
 .row_o(post_denoise_row_c),
 .col_o(post_denoise_col_c),
 .output_R(post_denoise_R_c),
 .output_G(post_denoise_G_c),
 .output_B(post_denoise_B_c)
);

// Frame sync pulse generator
reg sync, sync_c;
reg state, nextstate;

localparam WAIT = 1'b0;
localparam SYNC = 1'b1;
always @(*) begin
	sync_c = sync; 
	nextstate = state;
	
	case (state)
		WAIT: begin
			if (~post_denoise_vs) begin
				sync_c = 1'b1;
				nextstate = SYNC;
			end
		end
		
		SYNC: begin
			sync_c = 1'b0;
			if (post_denoise_vs) begin
				nextstate = WAIT;
			end
		end
	endcase
end

    
// Paddle draw stage

// Carry over signals
reg [7:0] post_draw_R, post_draw_G, post_draw_B;
reg [12:0] post_draw_row, post_draw_col;
reg post_draw_vs, post_draw_hs, post_draw_blank;
reg post_draw_sync;

// Delay signals by 2 cycles as paddle_draw has 2 cycle latency
reg [7:0] post_draw_R_d1, post_draw_R_d2;
reg [7:0] post_draw_G_d1, post_draw_G_d2;
reg [7:0] post_draw_B_d1, post_draw_B_d2;

reg [12:0] post_draw_row_d1, post_draw_row_d2;
reg [12:0] post_draw_col_d1, post_draw_col_d2;

reg post_draw_vs_d1, post_draw_vs_d2;
reg post_draw_hs_d1, post_draw_hs_d2;
reg post_draw_blank_d1, post_draw_blank_d2;
reg post_draw_sync_d1, post_draw_sync_d2;

reg post_draw_paddle, post_draw_paddle_d1, post_draw_paddle_d2;

// New Signals
wire in_p1_paddle_c, in_p2_paddle_c;
reg in_p1_paddle, in_p2_paddle;

wire [12:0] p1_paddle_center_x_c, p1_paddle_center_y_c;
wire [12:0] p2_paddle_center_x_c, p2_paddle_center_y_c;
reg  [12:0] p1_paddle_center_x,   p1_paddle_center_y;
reg  [12:0] p2_paddle_center_x,   p2_paddle_center_y;

paddle_draw  paddle_draw_p1 (
    .clk(VGA_CLK),
    .reset(RESET_N),
    .out_img(in_left_paddle),
    .row(post_denoise_row),
    .col(post_denoise_col),
    .V_sync(sync),
    .in_rect(in_p1_paddle_c),
    .center_x(p1_paddle_center_x_c),
    .center_y(p1_paddle_center_y_c)
  );

paddle_draw  paddle_draw_p2 (
    .clk(VGA_CLK),
    .reset(RESET_N),
    .out_img(in_right_paddle),
    .row(post_denoise_row),
    .col(post_denoise_col),
    .V_sync(sync),
    .in_rect(in_p2_paddle_c),
    .center_x(p2_paddle_center_x_c),
    .center_y(p2_paddle_center_y_c)
  );

// Vector Calculation Stage
// Carry over Signals
reg [7:0] post_vector_R, post_vector_G, post_vector_B;
reg [12:0] post_vector_row, post_vector_col;
reg post_vector_vs, post_vector_hs, post_vector_blank;
reg post_vector_sync;

reg post_vector_paddle;
reg post_vector_p1_paddle, post_vector_p2_paddle;
reg [12:0] post_vector_p1_center_x, post_vector_p1_center_y;
reg [12:0] post_vector_p2_center_x, post_vector_p2_center_y;

// New signals
wire signed [14:0] p1_nx_c, p1_ny_c, p2_nx_c, p2_ny_c;
wire signed [14:0] p1_lx_c, p1_ly_c, p2_lx_c, p2_ly_c;
reg signed [14:0] p1_nx, p1_ny, p2_nx, p2_ny;
reg signed [14:0] p1_lx, p1_ly, p2_lx, p2_ly;


vector_calculation  vector_calculation_p1 (
    .clk(VGA_CLK),
    .reset(RESET_N),
    .in_paddle(in_p1_paddle),
    .row(post_draw_row_d2),
    .col(post_draw_col_d2),
    .V_sync(post_draw_sync_d2),
    .nx(p1_nx_c),
    .ny(p1_ny_c),
    .lx(p1_lx_c),
    .ly(p1_ly_c)
  );

vector_calculation  vector_calculation_p2 (
    .clk(VGA_CLK),
    .reset(RESET_N),
    .in_paddle(in_p2_paddle),
    .row(post_draw_row_d2),
    .col(post_draw_col_d2),
    .V_sync(post_draw_sync_d2),
    .nx(p2_nx_c),
    .ny(p2_ny_c),
    .lx(p2_lx_c),
    .ly(p2_ly_c)
  );

// Game state stage
// Carry over signals
reg [7:0] post_gamestate_R, post_gamestate_G, post_gamestate_B;
reg [12:0] post_gamestate_row, post_gamestate_col;
reg post_gamestate_vs, post_gamestate_hs, post_gamestate_blank;

reg post_gamestate_p1_paddle, post_gamestate_p2_paddle;
reg post_gamestate_paddle;

// New signals
wire [12:0] ball_row_c, ball_col_c;
reg  [12:0] ball_row,   ball_col;
wire [9:0]  p1_score_c, p2_score_c;
reg  [9:0]  p1_score, p2_score;
wire p1_win_c, p2_win_c;
reg  p1_win, p2_win;


game_state  game_state_inst (
    .clk(VGA_CLK),
    .sync(post_vector_sync),
    .reset(SW[3]),
    .nx1(p1_nx),
    .ny1(p1_ny),
    .nx2(p2_nx),
    .ny2(p2_ny),
    .lx1(p1_lx),
    .ly1(p1_ly),
    .lx2(p2_lx),
    .ly2(p2_ly),
    .center_x1(post_vector_p1_center_x),
    .center_y1(post_vector_p1_center_y),
    .center_x2(post_vector_p2_center_x),
    .center_y2(post_vector_p2_center_y),
    .ball_col(ball_col_c),
    .ball_row(ball_row_c),
    .p1_score(p1_score_c),
    .p2_score(p2_score_c),
    .p1w(p1_win_c),
    .p2w(p2_win_c)
  );

  reg render_vs, render_hs, render_blank;
  reg render_vs_d1, render_hs_d1, render_blank_d1;
  reg render_vs_d2, render_hs_d2, render_blank_d2;

  // Render stage
  VGA_render  VGA_render_inst (
    .clk    (VGA_CLK),
    .game_en(SW[1]),
    .VGA_R(post_gamestate_R),
    .VGA_G(post_gamestate_G),
    .VGA_B(post_gamestate_B),
    .row(post_gamestate_row),
    .col(post_gamestate_col),
    .raw_paddle(post_gamestate_paddle),
    .paddle1(post_gamestate_p1_paddle),
    .paddle2(post_gamestate_p2_paddle),
    .ball_row(ball_row),
    .ball_col(ball_col),
    .p1_score(p1_score),
    .p2_score(p2_score),
    .p1_win(p1_win),
    .p2_win(p2_win),
    .render_R(VGA_R),
    .render_G(VGA_G),
    .render_B(VGA_B)
  );

  assign VGA_VS      = render_vs_d2;
  assign VGA_HS      = render_hs_d2;
  assign VGA_BLANK_N = render_blank_d2;

// Pipeline Registers
always @(posedge VGA_CLK) begin

    // Filter stage
    post_filter_R     <= post_filter_R_c;
    post_filter_G     <= post_filter_G_c;
    post_filter_B     <= post_filter_B_c;

    post_filter_vs    <= vga_vs_ni;
    post_filter_hs    <= vga_hs_ni;
    post_filter_blank <= vga_blank_ni;

    post_filter_col   <= col;
    post_filter_row   <= row;

    o_color            <= o_color_c;

    // Denoise Stage
    post_denoise_R     <= post_denoise_R_c;
    post_denoise_G     <= post_denoise_G_c;
    post_denoise_B     <= post_denoise_B_c;

    post_denoise_vs    <= post_denoise_vs_c;
    post_denoise_hs    <= post_denoise_hs_c;
    post_denoise_blank <= post_denoise_blank_c;

    in_left_paddle     <= in_left_paddle_c;
    in_right_paddle    <= in_right_paddle_c;

    post_denoise_col   <= post_denoise_col_c;
    post_denoise_row   <= post_denoise_row_c;
    sync <= sync_c;
    state <= nextstate;

    // Draw stage
    post_draw_R        <= post_denoise_R;
    post_draw_G        <= post_denoise_G;
    post_draw_B        <= post_denoise_B;

    post_draw_row      <= post_denoise_row;
    post_draw_col      <= post_denoise_col;

    post_draw_vs       <= post_denoise_vs;
    post_draw_hs       <= post_denoise_hs;
    post_draw_blank    <= post_denoise_blank;
    post_draw_sync     <= sync;

    // Delayed signals
    post_draw_R_d1     <= post_draw_R;
    post_draw_G_d1     <= post_draw_G;
    post_draw_B_d1     <= post_draw_B;
    post_draw_row_d1   <= post_draw_row;
    post_draw_col_d1   <= post_draw_col;
    post_draw_vs_d1    <= post_draw_vs;
    post_draw_hs_d1    <= post_draw_hs;
    post_draw_blank_d1 <= post_draw_blank;
    post_draw_sync_d1  <= post_draw_sync;

    post_draw_R_d2     <= post_draw_R_d1;
    post_draw_G_d2     <= post_draw_G_d1;
    post_draw_B_d2     <= post_draw_B_d1;
    post_draw_row_d2   <= post_draw_row_d1;
    post_draw_col_d2   <= post_draw_col_d1;
    post_draw_vs_d2    <= post_draw_vs_d1;
    post_draw_hs_d2    <= post_draw_hs_d1;
    post_draw_blank_d2 <= post_draw_blank_d1;
    post_draw_sync_d2  <= post_draw_sync_d1;

    post_draw_paddle    <= in_left_paddle || in_right_paddle;
    post_draw_paddle_d1 <= post_draw_paddle;
    post_draw_paddle_d2 <= post_draw_paddle_d1;

    in_p1_paddle       <= in_p1_paddle_c;
    in_p2_paddle       <= in_p2_paddle_c;
    p1_paddle_center_x <= p1_paddle_center_x_c;
    p1_paddle_center_y <= p1_paddle_center_y_c;
    p2_paddle_center_x <= p2_paddle_center_x_c;
    p2_paddle_center_y <= p2_paddle_center_y_c;

    // Vector Calculate Stage
    post_vector_R      <= post_draw_R_d2;
    post_vector_G      <= post_draw_G_d2;
    post_vector_B      <= post_draw_B_d2;

    post_vector_row      <= post_draw_row_d2;
    post_vector_col      <= post_draw_col_d2;

    post_vector_vs     <= post_draw_vs_d2;
    post_vector_hs     <= post_draw_hs_d2;
    post_vector_blank  <= post_draw_blank_d2;

    post_vector_sync   <= post_draw_sync_d2;

    post_vector_paddle <= post_draw_paddle_d2;

    post_vector_p1_paddle <= in_p1_paddle;
    post_vector_p2_paddle <= in_p2_paddle;

    post_vector_p1_center_x <= p1_paddle_center_x;
    post_vector_p1_center_y <= p1_paddle_center_y;
    post_vector_p2_center_x <= p2_paddle_center_x;
    post_vector_p2_center_y <= p2_paddle_center_y;

    p1_nx <= p1_nx_c;
    p1_ny <= p1_ny_c;
    p2_nx <= p2_nx_c;
    p2_ny <= p2_ny_c;

    p1_lx <= p1_lx_c;
    p1_ly <= p1_ly_c;
    p2_lx <= p2_lx_c;
    p2_ly <= p2_ly_c;

    // Game State Stage
    post_gamestate_R <= post_vector_R;
    post_gamestate_G <= post_vector_G;
    post_gamestate_B <= post_vector_B;

    post_gamestate_row <= post_vector_row;
    post_gamestate_col <= post_vector_col;

    post_gamestate_vs <= post_vector_vs;
    post_gamestate_hs <= post_vector_hs;
    post_gamestate_blank <= post_vector_blank;

    post_gamestate_paddle <= post_vector_paddle;


    post_gamestate_p1_paddle <= post_vector_p1_paddle;
    post_gamestate_p2_paddle <= post_vector_p2_paddle;

    ball_row   <= ball_row_c;
    ball_col   <= ball_col_c;
    p1_score   <= p1_score_c;
    p2_score   <= p2_score_c;
    p1_win     <= p1_win_c;
    p2_win     <= p2_win_c;

    render_vs  <= post_gamestate_vs;
    render_hs  <= post_gamestate_hs;
    render_blank <= post_gamestate_blank;

    render_vs_d1  <= render_vs;
    render_hs_d1  <= render_hs;
    render_blank_d1 <= render_blank;

    render_vs_d2  <= render_vs_d1;
    render_hs_d2  <= render_hs_d1;
    render_blank_d2 <= render_blank_d1;

end

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

endmodule
