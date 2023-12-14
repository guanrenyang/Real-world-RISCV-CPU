import "DPI-C" function void trap();
import "DPI-C" function void paddr_read(input int raddr, output int rdata);
import "DPI-C" function void paddr_write(input int waddr, input int wdata, input byte wmask);

module ysyx_23060061_Top (
  input clk,
  input rst, 
  // input [31 : 0] inst,
  // output [31 : 0] pc,
  output [31 : 0] ftrace_dnpc // used only for ftrace
);

	wire [31:0] pc;
	wire [31:0] dnpc;
	wire [31:0] inst;
	wire ifu_valid;

	ysyx_23060061_IFU_with_SRAM ifu(
		.clk(clk),
		.rst(rst),
		.dnpc(dnpc),
		.inst(inst),
		.pc(pc),
		.instValid(ifu_valid)
	);
	
	ID_EX_WB id_ex_wb(
		.clk(clk),
		.rst(rst),

		.inst(inst),
		.pc(pc),
		.ifu_valid(ifu_valid),
		.dnpc(dnpc),
		.ftrace_dnpc(ftrace_dnpc)
	);
  
endmodule

