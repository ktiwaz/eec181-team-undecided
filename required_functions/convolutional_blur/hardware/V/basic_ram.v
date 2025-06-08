`timescale 1ns / 1ps
module basic_ram #(
    parameter  DATA_WIDTH = 8,
    parameter  ADDR_WIDTH = 10,
    parameter  N_WORDS    = 640
)(
    input clk,
    input wr_en,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out,
    input [ADDR_WIDTH-1:0] addr_wr,
    input [ADDR_WIDTH-1:0] addr_rd
);

reg [DATA_WIDTH-1:0] mem [N_WORDS-1:0];
reg [DATA_WIDTH-1:0] data_out_i;

assign data_out = data_out_i;

always @(posedge clk) begin
    
    if (wr_en == 1'b1) begin
        mem[addr_wr] <= #1 data_in; // write mem
    end

    data_out_i <= #1 mem[addr_rd]; // read mem
end

endmodule
