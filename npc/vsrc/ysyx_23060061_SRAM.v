module ysyx_23060061_SRAM(
	// A SRAM which supports AXI-Lite interface
	input clk,
	input rst,

	input [31:0] araddr,
	input arvalid,
	output arready,

	output [31:0] rdata,
	output rresp,
	output rvalid,
	input rready,

	input [31:0] awaddr,
	input awvalid,
	output awready,

	input [31:0] wdata,
	input [3:0] wstrb,
	input wvalid,
	output wready,

	output bresp,
	output bvalid,
	input bready
);

endmodule