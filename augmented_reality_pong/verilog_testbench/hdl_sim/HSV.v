module HSV(
	input  [7:0] R,
	input  [7:0] G,
	input  [7:0] B,

   output signed [13:0] H_o,
   output        [7:0] S_o,
   output        [7:0] V_o
);

    wire [7:0] max_RG;
    wire [7:0] max;
    wire [7:0] min_RG;
    wire [7:0] min;
    wire [13:0] diff;
    reg signed [13:0] H;
    reg [7:0] S;

    assign max_RG   = (R > G) ? R : G;
    assign max  = (max_RG > B) ? max_RG : B;
    assign min_RG   = (R > G) ? G : R;
    assign min  = (min_RG > B) ? B : min_RG;
    assign diff = max - min;

    assign H_o = H;
    assign S_o = diff;
    assign V_o = max;

    always@(*) begin
       // H
	  H = 8'b0;
       if (max == 8'b0)begin
            H = 8'b0;
       end
       else if (max == R) begin
		  H = (G - B);
       end
       else if (max == G) begin
            H = ((diff<<1) + B - R);
       end
       else if (max == B) begin
            H = ((diff<<2) + R - G);
       end
    end
endmodule