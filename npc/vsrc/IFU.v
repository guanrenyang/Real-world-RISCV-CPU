// import "DPI-C" function void paddr_read(input int raddr, output int rdata);
module ysyx_23060061_IFU_with_SRAM(
	input clk,
	input rst,
	input [31:0] dnpc,

	output reg [31:0] inst,
	output reg instValid
);	

	wire [31:0] instImm_internal;

	reg [31:0] pc_old;
	reg [31:0] pc;
	
	// Combinationa logic
	always @(pc != pc_old) begin
		if (!rst) begin
			paddr_read(pc, instImm_internal);
			// instImm_internal = pc;
		end
	end

	// Sequential logic
	always @(posedge clk) begin
		if (rst) begin
			inst <= 0;
			pc <= 32'h80000000;
			pc_old <= 32'h80000000;
			instValid <= 0;
		end else begin
			inst <= instImm_internal;
			pc <= dnpc;
			pc_old <= pc;
			instValid <= (pc_old == pc) ? 0 : 1;
		end
	end	

endmodule