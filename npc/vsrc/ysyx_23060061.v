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
  output [3:0] io_master_awburst, // AXI4
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
  input [3:0] io_slave_awburst, // AXI4
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

	// // AXI4 reg signals
 //    wire io_awready;
 //    reg io_awvalid;
 //    reg [31:0]	io_awaddr;
 //    reg [3:0] io_awid; // AXI4
 //    reg [7:0] io_awlen; // AXI4
 //    reg [2:0] io_awsize; // AXI4
 //    reg [3:0] io_awburst; // AXI4
 //    wire io_wready;
 //    reg io_wvalid;
 //    reg [63:0] io_wdata;
 //    reg [7:0] io_wstrb;
 //    reg io_wlast; // AXI4
 //    reg io_bready;
 //    wire io_bvalid;
 //    wire [1:0] io_bresp;
 //    wire [3:0] io_bid; // AXI4
 //    wire io_arready;
 //    reg io_arvalid;
 //    reg [31:0] io_araddr;
 //    reg [3:0] io_arid; // AXI4
 //    reg [7:0] io_arlen; // AXI4
 //    reg [2:0] io_arsize; // AXI4
 //    reg [1:0] io_arburst; // AXI4
 //    reg io_rready;
 //    wire io_rvalid;
 //    wire [1:0] io_rresp;
 //    wire [63:0] io_rdata;
 //    wire io_rlast; // AXI4
 //    wire [3:0] io_rid; // AXI4
 //  
 //    assign io_awready = io_master_awready;
 //    assign io_master_awvalid = io_awvalid;
 //    assign io_master_awaddr = io_awaddr;
 //    assign io_master_awid = io_awid;
 //    assign io_master_awlen = io_awlen;
 //    assign io_master_awsize = io_awsize;
 //    assign io_master_awburst = io_awburst;
 //    assign io_wready = io_master_wready;
 //    assign io_master_wvalid = io_wvalid;
 //    assign io_master_wdata = io_wdata;
 //    assign io_master_wstrb = io_wstrb;
 //    assign io_master_wlast = io_wlast;
 //    assign io_master_bready = io_bready;
 //    assign io_bvalid = io_master_bvalid;
 //    assign io_bresp = io_master_bresp;
 //    assign io_bid = io_master_bid;
 //    assign io_arready = io_master_arready;
 //    assign io_master_arvalid = io_arvalid;
 //    assign io_master_araddr = io_araddr;
 //    assign io_master_arid = io_arid;
 //    assign io_master_arlen = io_arlen;
 //    assign io_master_arsize = io_arsize;
 //    assign io_master_arburst = io_arburst;
 //    assign io_master_rready = io_rready;
 //    assign io_rvalid = io_master_rvalid;
 //    assign io_rresp = io_master_rresp;
 //    assign io_rdata = io_master_rdata;
 //    assign io_rlast = io_master_rlast;
 //    assign io_rid = io_master_rid;

	// AXI-Lite IFU -> Arbitrater
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

	// AXI-Lite: LSU -> Arbitrater
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

	// // outports wire
	// wire        	arready;
	// wire [31:0] 	rdata;
	// wire [1:0]  	rresp;
	// wire        	rvalid;
	// wire        	awready;
	// wire        	wready;
	// wire [1:0]  	bresp;
	// wire        	bvalid;
	
	
	ysyx_23060061_AXILiteArbitrater busArbitrater(
		.clk         	( clock        ),
		.rst         	( ~reset         ),
		.araddr      	( io_master_araddr       ),
		.arvalid     	( io_master_arvalid      ),
		.arready     	( io_master_arready      ),
		.rdata       	( io_master_rdata[31:0]        ),
		.rresp       	( io_master_rresp        ),
		.rvalid      	( io_master_rvalid       ),
		.rready      	( io_master_rready       ),
		.awaddr      	( io_master_awaddr       ),
		.awvalid     	( io_master_awvalid      ),
		.awready     	( io_master_awready      ),
		.wdata       	( io_master_wdata[31:0]        ),
		.wstrb       	( io_master_wstrb[3:0]        ),
		.wvalid      	( io_master_wvalid       ),
		.wready      	( io_master_wready       ),
		.bresp       	( io_master_bresp        ),
		.bvalid      	( io_master_bvalid       ),
		.bready      	( io_master_bready       ),
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

