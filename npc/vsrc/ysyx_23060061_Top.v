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
	wire ifu_valid;

	wire RegWrite;

	wire [31:0] pc;
	wire [31:0] dnpc;
	wire [31:0] inst;

	wire [31:0] regDataWB;
	wire [31:0] regData1;
	wire [31:0] regData2;
	wire [4:0] rd;
	wire [4:0] rs1;
	wire [4:0] rs2;
		
	ysyx_23060061_GPRs #(5, 32) GPRs(
		.clk(clk),
		.rst(rst),
		.wdata(regDataWB),
		.waddr(rd),
    	.raddr1(rs1),
    	.raddr2(rs2),
    	.rdata1(regData1),
    	.rdata2(regData2),
		// enable signals
    	.wen(RegWrite & ifu_valid)
	);

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
		
		.rd(rd),
		.rs1(rs1),
		.rs2(rs2),
		.RegWrite(RegWrite),
		.regData1(regData1),
		.regData2(regData2),
		.regDataWB(regDataWB),

		.dnpc(dnpc),
		.ftrace_dnpc(ftrace_dnpc)
	);

endmodule

