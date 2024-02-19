import "DPI-C" function void trap();
import "DPI-C" function void paddr_read(input int raddr, output int rdata);
import "DPI-C" function void paddr_write(input int waddr, input int wdata, input byte wmask);
import "DPI-C" function void uart_display(input int waddr, input int wdata);

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
	wire lsu_ready; // LSU ready signal

	wire lsu_valid; // LSU valid signal
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

	// AXI-Lite IFU->SRAM
	wire [31:0] ifu_araddr;
	wire ifu_arvalid;
	wire ifu_arready;

	wire [31:0] ifu_rdata;
	wire [1:0] ifu_rresp;
	wire ifu_rvalid;
	wire ifu_rready;

	wire [31:0] ifu_awaddr;
	wire ifu_awvalid;
	wire ifu_awready;

	wire [31:0] ifu_wdata;
	wire [3:0] ifu_wstrb;
	wire ifu_wvalid;
	wire ifu_wready;

	wire [1:0] ifu_bresp;
	wire ifu_bvalid;
	wire ifu_bready;

	// AXI-Lite: LSU->SRAM
	wire [31:0] lsu_araddr;
	wire lsu_arvalid;
	wire lsu_arready;

	wire [31:0] lsu_rdata;
	wire [1:0] lsu_rresp;
	wire lsu_rvalid;
	wire lsu_rready;

	wire [31:0] lsu_awaddr;
	wire lsu_awvalid;
	wire lsu_awready;

	wire [31:0] lsu_wdata;
	wire [3:0] lsu_wstrb;
	wire lsu_wvalid;
	wire lsu_wready;

	wire [1:0] lsu_bresp;
	wire lsu_bvalid;
	wire lsu_bready;

	// AXI-Lite 
	wire [31:0] araddr;
	wire arvalid;
	wire arready;

	wire [31:0] rdata;
	wire [1:0] rresp;
	wire rvalid;
	wire rready;

	wire [31:0] awaddr;
	wire awvalid;
	wire awready;

	wire [31:0] wdata;
	wire [3:0] wstrb;
	wire wvalid;
	wire wready;

	wire [1:0] bresp;
	wire bvalid;
	wire bready;

	ysyx_23060061_Reg #(32, 32'h80000000) pc_reg(
		.clk(clk),
		.rst(rst),
		.din(lsu_valid ? dnpc : pc),
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
    	.wen(RegWrite & lsu_valid)
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
    	.ecall(ecall & lsu_valid),
    	.csrEn(csrEn & lsu_valid)
  	);

	ysyx_23060061_SRAM InstMem(
		.clk(clk),
		.rst(~rst), // reset of AXI is activate low

		.araddr(araddr),
		.arvalid(arvalid),
		.arready(arready),

		.rdata(rdata),
		.rresp(rresp),
		.rvalid(rvalid),
		.rready(rready),

		.awaddr(awaddr),
		.awvalid(awvalid),
		.awready(awready),

		.wdata(wdata),
		.wstrb(wstrb),
		.wvalid(wvalid),
		.wready(wready),

		.bresp(bresp),
		.bvalid(bvalid),
		.bready(bready)
	);
	
	// ysyx_23060061_SRAM DataMem(
	// 	.clk(clk),
	// 	.rst(~rst), // reset of AXI is activate low
	//
	// 	.araddr(araddr),
	// 	.arvalid(arvalid),
	// 	.arready(arready),
	//
	// 	.rdata(rdata),
	// 	.rresp(rresp),
	// 	.rvalid(rvalid),
	// 	.rready(rready),
	//
	// 	.awaddr(awaddr),
	// 	.awvalid(awvalid),
	// 	.awready(awready),
	//
	// 	.wdata(wdata),
	// 	.wstrb(wstrb),
	// 	.wvalid(wvalid),
	// 	.wready(wready),
	//
	// 	.bresp(bresp),
	// 	.bvalid(bvalid),
	// 	.bready(bready)
	// );

	ysyx_23060061_AXILiteArbitrater busArbitrater(
		.clk         	( clk          ),
		.rst         	( ~rst          ),
		.araddr      	( araddr       ),
		.arvalid     	( arvalid      ),
		.arready     	( arready      ),
		.rdata       	( rdata        ),
		.rresp       	( rresp        ),
		.rvalid      	( rvalid       ),
		.rready      	( rready       ),
		.awaddr      	( awaddr       ),
		.awvalid     	( awvalid      ),
		.awready     	( awready      ),
		.wdata       	( wdata        ),
		.wstrb       	( wstrb        ),
		.wvalid      	( wvalid       ),
		.wready      	( wready       ),
		.bresp       	( bresp        ),
		.bvalid      	( bvalid       ),
		.bready      	( bready       ),
		.ifu_araddr  	( ifu_araddr   ),
		.ifu_arvalid 	( ifu_arvalid  ),
		.ifu_arready 	( ifu_arready  ),
		.ifu_rdata   	( ifu_rdata    ),
		.ifu_rresp   	( ifu_rresp    ),
		.ifu_rvalid  	( ifu_rvalid   ),
		.ifu_rready  	( ifu_rready   ),
		.ifu_awaddr  	( ifu_awaddr   ),
		.ifu_awvalid 	( ifu_awvalid  ),
		.ifu_awready 	( ifu_awready  ),
		.ifu_wdata   	( ifu_wdata    ),
		.ifu_wstrb   	( ifu_wstrb    ),
		.ifu_wvalid  	( ifu_wvalid   ),
		.ifu_wready  	( ifu_wready   ),
		.ifu_bresp   	( ifu_bresp    ),
		.ifu_bvalid  	( ifu_bvalid   ),
		.ifu_bready  	( ifu_bready   ),
		.lsu_araddr     ( lsu_araddr   ),
		.lsu_arvalid 	( lsu_arvalid  ),
		.lsu_arready 	( lsu_arready  ),
		.lsu_rdata   	( lsu_rdata    ),
		.lsu_rresp   	( lsu_rresp    ),
		.lsu_rvalid  	( lsu_rvalid   ),
		.lsu_rready  	( lsu_rready   ),
		.lsu_awaddr  	( lsu_awaddr   ),
		.lsu_awvalid 	( lsu_awvalid  ),
		.lsu_awready 	( lsu_awready  ),
		.lsu_wdata   	( lsu_wdata    ),
		.lsu_wstrb   	( lsu_wstrb    ),
		.lsu_wvalid  	( lsu_wvalid   ),
		.lsu_wready  	( lsu_wready   ),
		.lsu_bresp   	( lsu_bresp    ),
		.lsu_bvalid  	( lsu_bvalid   ),
		.lsu_bready  	( lsu_bready   )
	);
	
	ysyx_23060061_IFU_with_SRAM ifu(
		.clk(clk),
		.rst(~rst), // reset of AXI is activate low
		.dnpc(dnpc),
		.inst(inst),
		.pc(pc),
		.instValid(ifu_valid),
		.iduReady(idu_ready),

		// For IFU->SRAM in AXI-Lite
		.araddr(ifu_araddr),
		.arvalid(ifu_arvalid),
		.arready(ifu_arready),

		.rdata(ifu_rdata),
		.rresp(ifu_rresp),
		.rvalid(ifu_rvalid),
		.rready(ifu_rready),

		.awaddr(ifu_awaddr),
		.awvalid(ifu_awvalid),
		.awready(ifu_awready),

		.wdata(ifu_wdata),
		.wstrb(ifu_wstrb),
		.wvalid(ifu_wvalid),
		.wready(ifu_wready),

		.bresp(ifu_bresp),
		.bvalid(ifu_bvalid),
		.bready(ifu_bready)
	);
	
	ysyx_23060061_IDEXU id_ex_u( 
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
		.lsu_ready(lsu_ready),
		.WBSel(WBSel),
		// .memDataR(memDataR),
		.aluOut(aluOut),
		.snpc(snpc),
		.dnpc(dnpc),
		.ftrace_dnpc(ftrace_dnpc)
	);

	ysyx_23060061_LSU lsu(
		.clk(clk),
		.rst(~rst),
		.memExt(memExt),
		.MemRW(MemRW),
		.memAddr(memAddr),
		.memDataW(memDataW),
		.wmask(wmask),
		.exu_valid(exu_valid),
		.lsu_ready(lsu_ready),
		.lsu_valid(lsu_valid),
		.wbu_ready(wbu_ready),
		.memDataR(memDataR),

		// For LSU->SRAM in AXI-Lite interface
		.araddr(lsu_araddr),
		.arvalid(lsu_arvalid),
		.arready(lsu_arready),

		.rdata(lsu_rdata),
		.rresp(lsu_rresp),
		.rvalid(lsu_rvalid),
		.rready(lsu_rready),

		.awaddr(lsu_awaddr),
		.awvalid(lsu_awvalid),
		.awready(lsu_awready),

		.wdata(lsu_wdata),
		.wstrb(lsu_wstrb),
		.wvalid(lsu_wvalid),
		.wready(lsu_wready),

		.bresp(lsu_bresp),
		.bvalid(lsu_bvalid),
		.bready(lsu_bready)
  	);

	ysyx_23060061_WBU wbu(
		.clk(clk),
		.rst(rst),

		.lsu_valid(lsu_valid),
		.wbu_ready(wbu_ready),
		.WBSel(WBSel),
		.memDataR(memDataR),
		.aluOut(aluOut),
		.snpc(snpc),
		.csrReadData(csrReadData),
		.regDataWB(regDataWB)
	);

endmodule

