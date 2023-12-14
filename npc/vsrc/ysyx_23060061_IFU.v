// import "DPI-C" function void paddr_read(input int raddr, output int rdata);
module ysyx_23060061_IFU_with_SRAM(
	input clk,
	input rst,
	input [31:0] dnpc,

	output reg [31:0] inst,
);	

	wire [31:0] instImm_internal;

	reg [31:0] pc_old;
	reg [31:0] pc;
	
	reg instValid;

	// Combinationa logic
	always @(pc) begin
		if (!rst) begin
			paddr_read(pc, instImm_internal);
		end
	end

	// Sequential logic
	always @(posedge clk) begin
		if (rst) begin
			inst <= 0;
			pc_old <= 0;
			pc <= 0;
		end else begin
			inst <= instImm_internal;
			pc <= dnpc;
			pc_old <= pc;
		end
	end	
	
	always @(posedge clk) begin
		if (pc_old == pc) begin
			instValid <= 0;
		end else begin
			instValid <= 1;
		end
	end


 
endmodule