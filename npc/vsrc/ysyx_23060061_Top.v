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
	// ifu->idu
	wire ifu_valid; // IFU valid signal
	wire idu_ready; // IDU ready signal

	wire exu_valid; // EXU valid signal

	// wire mfu_valid; // MFU valid signal
	wire wbu_ready; // WBU ready signal
	wire RegWrite; // GPR write enable
	wire csrEn; // CSR write enable
	wire ecall; // ecall signal
	wire [1:0] WBSel; // WBU write back select
	wire [31:0] memDataR; // LSU read data
	wire [31:0] aluOut; // ALU output
	
	// For LSU
	wire [2:0] memExt;
	wire [1:0] MemRW;
	wire [31:0] memAddr;
	wire [31:0] memDataW;
	wire [3:0] wmask;

	wire [31:0] pc;
	wire [31:0] dnpc;
	wire [31:0] inst;
	wire [31:0] snpc; // next PC

	// For GPRs
	wire [31:0] regDataWB;
	wire [31:0] regData1;
	wire [31:0] regData2;
	wire [4:0] rd;
	wire [4:0] rs1;
	wire [4:0] rs2;
	// For CSRs
	wire [11:0] csrId;
	wire [31:0] csrWriteData;
	wire [31:0] csrReadData;
	wire [31:0] mtvec;
	wire [31:0] mepc;
			
	ysyx_23060061_Reg #(32, 32'h80000000) pc_reg(
		.clk(clk),
		.rst(rst),
		.din(exu_valid ? dnpc : pc),
		.dout(pc),
		.wen(1'b1)
	);

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

  	ysyx_23060061_CSRs #(32) CSRs(
    	.clk(clk),
		.rst(rst),
    	.csrId(csrId),
    	.wdata(csrWriteData),
    	.rdata(csrReadData),
    	.pc(pc),
    	.mtvec(mtvec),
    	.mepc(mepc),
		// enable signals
    	.ecall(ecall & ifu_valid),
    	.csrEn(csrEn & ifu_valid)
  	);

	ysyx_23060061_IFU_with_SRAM ifu(
		.clk(clk),
		.rst(rst),
		.dnpc(dnpc),
		.inst(inst),
		.pc(pc),
		.instValid(ifu_valid),
		.iduReady(idu_ready)
	);
	
	ysyx_23060061_ID_EX_WB id_ex_wb( 
		.clk(clk),
		.rst(rst),

		.inst(inst),
		.pc(pc),
		.ifu_valid(ifu_valid),
		.idu_ready(idu_ready),
		
		.rd(rd),
		.rs1(rs1),
		.rs2(rs2),
		.RegWrite(RegWrite),
		.regData1(regData1),
		.regData2(regData2),
		.regDataWB(regDataWB),

		.csrEn(csrEn),
		.csrId(csrId),
		.csrWriteData(csrWriteData),
		.ecall(ecall),
		.csrReadData(csrReadData),
		.mtvec(mtvec),
		.mepc(mepc),

		.memExt(memExt),
		.MemRW(MemRW),
		.memAddr(memAddr),
		.memDataW(memDataW),
		.wmask(wmask),

		.exu_valid(exu_valid),
		.wbu_ready(wbu_ready),
		.WBSel(WBSel),
		// .memDataR(memDataR),
		.aluOut(aluOut),
		.snpc(snpc),
		.dnpc(dnpc),
		.ftrace_dnpc(ftrace_dnpc)
	);

	ysyx_23060061_LSU lsu(
		.memExt(memExt),
		.MemRW(MemRW),
		.memAddr(memAddr),
		.memDataW(memDataW),
		.wmask(wmask),
		.exu_valid(exu_valid),
		.memDataR(memDataR)
  	);

	ysyx_23060061_WBU wbu(
		.clk(clk),
		.rst(rst),

		.mfu_valid(exu_valid),
		.wbu_ready(wbu_ready),
		.WBSel(WBSel),
		.memDataR(memDataR),
		.aluOut(aluOut),
		.snpc(snpc),
		.csrReadData(csrReadData),
		.regDataWB(regDataWB)
	);

endmodule

