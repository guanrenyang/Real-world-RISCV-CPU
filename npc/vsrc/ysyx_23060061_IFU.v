// import "DPI-C" function void paddr_read(input int raddr, output int rdata);
module ysyx_23060061_IFU_with_SRAM(
	input clk,
	input rst,
	input [31:0] dnpc,
	input [31:0] pc,
	output reg [31:0] inst,
	output reg instValid,
	input iduReady,
	
	output [31:0] araddr,
	output arvalid,
	input arready,

	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output rready,

	output [31:0] awaddr,
	output awvalid,
	input awready,

	output [31:0] wdata,
	output [3:0] wstrb,
	output wvalid,
	input wready,

	input bresp,
	input bvalid,
	output bready
);	

	reg [31:0] instImm_internal;

	reg [31:0] pc_old;
	
	// Combinationa logic
	always @(pc!=pc_old) begin
		if (!rst) begin
			paddr_read(pc, instImm_internal);
		end
	end

	// Sequential logic
	always @(posedge clk) begin
		if (rst) begin
			inst <= 0;
			pc_old <= 0;
			instValid <= 0;
		end else begin
			inst <= instImm_internal;
			pc_old <= pc;
			// instValid <= (pc_old == pc) ? 0 : 1;
			instValid <= ~iduReady;
		end
	end	
endmodule