module image_dumper #(
    parameter WIDTH       = 640,
    parameter HEIGHT      = 480,
    parameter INDEX_WIDTH = 19
    ) (
    input clk,
    input reset_n,
    input [7:0] VGA_R,
    input [7:0] VGA_G,
    input [7:0] VGA_B,
    input valid
);

reg dump, dumped;
reg [INDEX_WIDTH-1:0] index;

localparam MEM_DEPTH = WIDTH * HEIGHT;

reg [23:0] image_mem [0:MEM_DEPTH-1]; // Each entry is {R[7:0], G[7:0], B[7:0]}

always @(posedge clk) begin
    if(~reset_n) begin
        dump <= 0;
        dumped <= 0;
        index <= 0;
    end else begin
        if (valid) begin
            if (index < MEM_DEPTH) begin
                image_mem[index][23:16] <= VGA_R;
                image_mem[index][15:8]  <= VGA_G;
                image_mem[index][7:0]   <= VGA_B;
                index <= index + 1;
            end else begin
                dump <= 1;
            end
        end
    end
end

integer j, out_file;
always @(posedge clk) begin
    if(dump & ~dumped) begin
        out_file = $fopen("output_pixels.txt", "w");
        if (out_file == 0) begin
          $display("Error: Could not open output file.");
          $finish;
        end
    
        for (j = 0; j < MEM_DEPTH; j = j + 1) begin
          $fdisplay(out_file, "0x%02x, 0x%02x, 0x%02x",
            image_mem[j][23:16], image_mem[j][15:8], image_mem[j][7:0]);
        end
    
        $fclose(out_file);
        dumped <= 1; // Prevent dumping repeatedly
        $display("Memory dumped to output_pixels.txt");
        $finish;
    end
end

endmodule