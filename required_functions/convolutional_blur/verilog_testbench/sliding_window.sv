module sliding_window #(parameter NUMBER_OF_LINES = 3, 
                            parameter WIDTH = 640, 
                            parameter BUS_SIZE = 25)
(
    input clock,
    input EN,
    input [BUS_SIZE-1:0] data,
    output [BUS_SIZE-1:0] dataout [0:NUMBER_OF_LINES-1][0:NUMBER_OF_LINES-1] // 3D array output
);

// Total number of elements in the buffer
localparam BUFFER_SIZE = NUMBER_OF_LINES * WIDTH;

// shift register
reg [BUS_SIZE-1:0] fp_delay [0:BUFFER_SIZE-1];

always @(posedge clock) begin
    if (EN) begin
        fp_delay[0] <= data; // Store input data in the first position
    end
    else begin
        fp_delay[0] <= fp_delay[0]; // Retain the previous data if not enabled
    end
end

genvar index;
generate
    for (index = 1; index < BUFFER_SIZE ; index = index + 1) begin: delay_generate
        always @(posedge clock) begin
            if (EN) begin
                fp_delay[index] <= fp_delay[index-1]; // Shift data down the line
            end
            else begin
                fp_delay[index] <= fp_delay[index]; // Retain previous data
            end
        end
    end
endgenerate

// Generate assignments for the 3D array (lines x lines x bus_width)
genvar i, j;
generate
    for (i = 0; i < NUMBER_OF_LINES; i = i + 1) begin: row
        for (j = 0; j < NUMBER_OF_LINES; j = j + 1) begin: col
            assign dataout[i][j] = fp_delay[BUFFER_SIZE - j*WIDTH - i - 1]; // Access each element in the delay buffer
        end
    end
endgenerate
 
endmodule
