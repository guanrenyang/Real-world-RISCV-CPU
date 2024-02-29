import "DPI-C" function void trap();
import "DPI-C" function void paddr_read(input int raddr, output int rdata);
import "DPI-C" function void paddr_write(input int waddr, input int wdata, input byte wmask);
import "DPI-C" function void uart_display(input int waddr, input int wdata);

module ysyx_23060061 (
  input clock,
  input reset,
  input io_interrupt,

  // AXI4-Master
  // write address signal
  input io_master_awready,
  output io_master_awvalid,
  output [31:0]	io_master_awaddr,
  output [3:0] io_master_awid, // AXI4
  output [7:0] io_master_awlen, // AXI4
  output [2:0] io_master_awsize, // AXI4
  output [1:0] io_master_awburst, // AXI4
  // write data channel
  input io_master_wready,
  output io_master_wvalid,
  output [63:0] io_master_wdata,
  output [7:0] io_master_wstrb,
  output io_master_wlast, // AXI4
  // wirte response channel
  output io_master_bready,
  input io_master_bvalid,
  input [1:0] io_master_bresp,
  input [3:0] io_master_bid, // AXI4
  // read address channel
  input io_master_arready,
  output io_master_arvalid,
  output [31:0] io_master_araddr,
  output [3:0] io_master_arid, // AXI4
  output [7:0] io_master_arlen, // AXI4
  output [2:0] io_master_arsize, // AXI4
  output [1:0] io_master_arburst, // AXI4
  // read data channel
  output io_master_rready,
  input io_master_rvalid,
  input [1:0] io_master_rresp,
  input [63:0] io_master_rdata,
  input io_master_rlast, // AXI4
  input [3:0] io_master_rid, // AXI4
  
  // AXI4-Slave
  output io_slave_awready,
  input io_slave_awvalid,
  input [31:0]	io_slave_awaddr,
  input [3:0] io_slave_awid, // AXI4
  input [7:0] io_slave_awlen, // AXI4
  input [2:0] io_slave_awsize, // AXI4
  input [1:0] io_slave_awburst, // AXI4
  output io_slave_wready,
  input io_slave_wvalid,
  input [63:0] io_slave_wdata,
  input [7:0] io_slave_wstrb,
  input io_slave_wlast, // AXI4
  input io_slave_bready,
  output io_slave_bvalid,
  output [1:0] io_slave_bresp,
  output [3:0] io_slave_bid, // AXI4
  output io_slave_arready,
  input io_slave_arvalid,
  input [31:0] io_slave_araddr,
  input [3:0] io_slave_arid, // AXI4
  input [7:0] io_slave_arlen, // AXI4
  input [2:0] io_slave_arsize, // AXI4
  input [1:0] io_slave_arburst, // AXI4
  input io_slave_rready,
  output io_slave_rvalid,
  output [1:0] io_slave_rresp,
  output [63:0] io_slave_rdata,
  output io_slave_rlast, // AXI4
  output [3:0] io_slave_rid // AXI4
  // output [31 : 0] ftrace_dnpc // used only for ftrace，
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

	// AXI-Lite IFU -> Arbitrater
	wire [31:0] ifu_araddr;
	wire ifu_arvalid;
	wire ifu_arready;
	wire [3:0] ifu_arid; // AXI4
	wire [7:0] ifu_arlen; // AXI4
	wire [2:0] ifu_arsize; // AXI4
	wire [1:0] ifu_arburst; // AXI4

	wire [31:0] ifu_rdata;
	wire [1:0] ifu_rresp;
	wire ifu_rvalid;
	wire ifu_rready;
	wire ifu_rlast; // AXI4
	wire [3:0] ifu_rid; // AXI4

	wire [31:0] ifu_awaddr;
	wire ifu_awvalid;
	wire [3:0] ifu_awid; // AXI4
	wire [7:0] ifu_awlen; // AXI4
	wire [2:0] ifu_awsize; // AXI4
	wire [1:0] ifu_awburst; // AXI4
	wire ifu_awready;

	wire [31:0] ifu_wdata;
	wire [3:0] ifu_wstrb;
	wire ifu_wvalid;
	wire ifu_wlast; // AXI4
	wire ifu_wready;

	wire [1:0] ifu_bresp;
	wire ifu_bvalid;
	wire [3:0] ifu_bid; // AXI4
	wire ifu_bready;

	// AXI-Lite: LSU -> Arbitrater
	wire [31:0] lsu_araddr;
	wire lsu_arvalid;
	wire lsu_arready;
	wire [3:0] lsu_arid; // AXI4
	wire [7:0] lsu_arlen; // AXI4
	wire [2:0] lsu_arsize; // AXI4
	wire [1:0] lsu_arburst; // AXI4

	wire [31:0] lsu_rdata;
	wire [1:0] lsu_rresp;
	wire lsu_rvalid;
	wire lsu_rready;
	wire lsu_rlast; // AXI4
	wire [3:0] lsu_rid; // AXI4

	wire [31:0] lsu_awaddr;
	wire lsu_awvalid;
	wire [3:0] lsu_awid; // AXI4
	wire [7:0] lsu_awlen; // AXI4
	wire [2:0] lsu_awsize; // AXI4
	wire [1:0] lsu_awburst; // AXI4
	wire lsu_awready;

	wire [31:0] lsu_wdata;
	wire [3:0] lsu_wstrb;
	wire lsu_wvalid;
	wire lsu_wlast; // AXI4
	wire lsu_wready;

	wire [1:0] lsu_bresp;
	wire lsu_bvalid;
	wire [3:0] lsu_bid; // AXI4
	wire lsu_bready;

	// AXI-Lite 
	ysyx_23060061_Reg #(32, 32'h80000000) pc_reg(
		.clk(clock),
		.rst(reset),
		.din(lsu_valid ? dnpc : pc),
		.dout(pc),
		.wen(1'b1)
	);

	ysyx_23060061_GPRs #(5, 32) GPRs(
		.clk(clock),
		.rst(reset),
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
    	.clk(clock),
		.rst(reset),
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

	ysyx_23060061_AXILiteArbitrater busArbitrater(
		.clk         	( clock        ),
		.rst         	( ~reset         ),
		.araddr      	( io_master_araddr       ),
		.arvalid     	( io_master_arvalid      ),
		.arready     	( io_master_arready      ),
		.arid			( io_master_arid         ),
		.arlen			( io_master_arlen        ),
		.arsize			( io_master_arsize       ),
		.arburst		( io_master_arburst      ),
		.rdata       	( io_master_rdata[31:0]        ),
		.rresp       	( io_master_rresp        ),
		.rvalid      	( io_master_rvalid       ),
		.rready      	( io_master_rready       ),
		.rlast	   	 	( io_master_rlast        ),
		.rid			( io_master_rid          ),
		.awaddr      	( io_master_awaddr       ),
		.awvalid     	( io_master_awvalid      ),
		.awid			( io_master_awid         ),
		.awlen			( io_master_awlen        ),
		.awsize			( io_master_awsize       ),
		.awburst		( io_master_awburst      ),
		.awready     	( io_master_awready      ),
		.wdata       	( io_master_wdata[31:0]        ),
		.wstrb       	( io_master_wstrb[3:0]        ),
		.wvalid      	( io_master_wvalid       ),
		.wlast	   		( io_master_wlast        ),
		.wready      	( io_master_wready       ),
		.bresp       	( io_master_bresp        ),
		.bvalid      	( io_master_bvalid       ),
		.bid			( io_master_bid          ),
		.bready      	( io_master_bready       ),
		.ifu_araddr  	( ifu_araddr   ),
		.ifu_arvalid 	( ifu_arvalid  ),
		.ifu_arready 	( ifu_arready  ),
		.ifu_arid		( ifu_arid     ),
		.ifu_arlen		( ifu_arlen    ),
		.ifu_arsize		( ifu_arsize   ),
		.ifu_arburst	( ifu_arburst  ),
		.ifu_rdata   	( ifu_rdata    ),
		.ifu_rresp   	( ifu_rresp    ),
		.ifu_rvalid  	( ifu_rvalid   ),
		.ifu_rready  	( ifu_rready   ),
		.ifu_rlast   	( ifu_rlast    ),
		.ifu_rid     	( ifu_rid      ),
		.ifu_awaddr  	( ifu_awaddr   ),
		.ifu_awvalid 	( ifu_awvalid  ),
		.ifu_awid		( ifu_awid     ),
		.ifu_awlen		( ifu_awlen    ),
		.ifu_awsize		( ifu_awsize   ),
		.ifu_awburst	( ifu_awburst  ),
		.ifu_awready 	( ifu_awready  ),
		.ifu_wdata   	( ifu_wdata    ),
		.ifu_wstrb   	( ifu_wstrb    ),
		.ifu_wvalid  	( ifu_wvalid   ),
		.ifu_wlast   	( ifu_wlast    ),
		.ifu_wready  	( ifu_wready   ),
		.ifu_bresp   	( ifu_bresp    ),
		.ifu_bvalid  	( ifu_bvalid   ),
		.ifu_bid	 	( ifu_bid      ),
		.ifu_bready  	( ifu_bready   ),
		.lsu_araddr     ( lsu_araddr   ),
		.lsu_arvalid 	( lsu_arvalid  ),
		.lsu_arready 	( lsu_arready  ),
		.lsu_arid		( lsu_arid     ),
		.lsu_arlen		( lsu_arlen    ),
		.lsu_arsize		( lsu_arsize   ),
		.lsu_arburst	( lsu_arburst  ),
		.lsu_rdata   	( lsu_rdata    ),
		.lsu_rresp   	( lsu_rresp    ),
		.lsu_rvalid  	( lsu_rvalid   ),
		.lsu_rready  	( lsu_rready   ),
		.lsu_rlast   	( lsu_rlast    ),
		.lsu_rid     	( lsu_rid      ),
		.lsu_awaddr  	( lsu_awaddr   ),
		.lsu_awvalid 	( lsu_awvalid  ),
		.lsu_awid		( lsu_awid     ),
		.lsu_awlen		( lsu_awlen    ),
		.lsu_awsize		( lsu_awsize   ),
		.lsu_awburst	( lsu_awburst  ),
		.lsu_awready 	( lsu_awready  ),
		.lsu_wdata   	( lsu_wdata    ),
		.lsu_wstrb   	( lsu_wstrb    ),
		.lsu_wvalid  	( lsu_wvalid   ),
		.lsu_wlast   	( lsu_wlast    ),
		.lsu_wready  	( lsu_wready   ),
		.lsu_bresp   	( lsu_bresp    ),
		.lsu_bvalid  	( lsu_bvalid   ),
		.lsu_bid	 	( lsu_bid      ),
		.lsu_bready  	( lsu_bready   )
	);
	
	ysyx_23060061_IFU ifu(
		.clk(clock),
		.rst(~reset), // reset of AXI is activate low
		.dnpc(dnpc),
		.inst(inst),
		.pc(pc),
		.instValid(ifu_valid),
		.iduReady(idu_ready),

		// For IFU->SRAM in AXI-Lite
		.araddr(ifu_araddr),
		.arvalid(ifu_arvalid),
		.arready(ifu_arready),
		.arid(ifu_arid),
		.arlen(ifu_arlen),
		.arsize(ifu_arsize),
		.arburst(ifu_arburst),

		.rdata(ifu_rdata),
		.rresp(ifu_rresp),
		.rvalid(ifu_rvalid),
		.rready(ifu_rready),
		.rlast(ifu_rlast),
		.rid(ifu_rid),

		.awaddr(ifu_awaddr),
		.awvalid(ifu_awvalid),
		.awid(ifu_awid),
		.awlen(ifu_awlen),
		.awsize(ifu_awsize),
		.awburst(ifu_awburst),
		.awready(ifu_awready),

		.wdata(ifu_wdata),
		.wstrb(ifu_wstrb),
		.wvalid(ifu_wvalid),
		.wlast(ifu_wlast),
		.wready(ifu_wready),

		.bresp(ifu_bresp),
		.bvalid(ifu_bvalid),
		.bid(ifu_bid),
		.bready(ifu_bready)
	);
	
	ysyx_23060061_IDEXU id_ex_u( 
		.clk(clock),
		.rst(reset),

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
		.dnpc(dnpc)
		// .ftrace_dnpc(ftrace_dnpc)
	);

	ysyx_23060061_LSU lsu(
		.clk(clock),
		.rst(~reset),
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
		.arid(lsu_arid),
		.arlen(lsu_arlen),
		.arsize(lsu_arsize),
		.arburst(lsu_arburst),

		.rdata(lsu_rdata),
		.rresp(lsu_rresp),
		.rvalid(lsu_rvalid),
		.rready(lsu_rready),
		.rlast(lsu_rlast),
		.rid(lsu_rid),

		.awaddr(lsu_awaddr),
		.awvalid(lsu_awvalid),
		.awid(lsu_awid),
		.awlen(lsu_awlen),
		.awsize(lsu_awsize),
		.awburst(lsu_awburst),
		.awready(lsu_awready),

		.wdata(lsu_wdata),
		.wstrb(lsu_wstrb),
		.wvalid(lsu_wvalid),
		.wlast(lsu_wlast),
		.wready(lsu_wready),

		.bresp(lsu_bresp),
		.bvalid(lsu_bvalid),
		.bid(lsu_bid),
		.bready(lsu_bready)
  	);

	ysyx_23060061_WBU wbu(
		.clk(clock),
		.rst(reset),

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

