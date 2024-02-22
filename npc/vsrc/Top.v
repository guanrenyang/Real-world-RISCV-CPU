module Top(
	input clock,
	input reset
);
	// CPU(Arbitrator) -> Xbar
	wire [31:0] araddr_cpu2xbar;
	wire arvalid_cpu2xbar;
	wire arready_cpu2xbar;

	wire [63:0] rdata_cpu2xbar;
	wire [1:0] rresp_cpu2xbar;
	wire rvalid_cpu2xbar;
	wire rready_cpu2xbar;

	wire [31:0] awaddr_cpu2xbar;
	wire awvalid_cpu2xbar;
	wire awready_cpu2xbar;

	wire [63:0] wdata_cpu2xbar;
	wire [7:0] wstrb_cpu2xbar;
	wire wvalid_cpu2xbar;
	wire wready_cpu2xbar;

	wire [1:0] bresp_cpu2xbar;
	wire bvalid_cpu2xbar;
	wire bready_cpu2xbar;

	// Xbar -> CLINT
	wire [31:0] araddr_xbar2clint;
	wire arvalid_xbar2clint;
	wire arready_xbar2clint;

	wire [31:0] rdata_xbar2clint;
	wire [1:0] rresp_xbar2clint;
	wire rvalid_xbar2clint;
	wire rready_xbar2clint;

	wire [31:0] awaddr_xbar2clint;
	wire awvalid_xbar2clint;
	wire awready_xbar2clint;

	wire [31:0] wdata_xbar2clint;
	wire [3:0] wstrb_xbar2clint;
	wire wvalid_xbar2clint;
	wire wready_xbar2clint;

	wire [1:0] bresp_xbar2clint;
	wire bvalid_xbar2clint;
	wire bready_xbar2clint;

	// Xbar -> SRAM
	wire [31:0] araddr_xbar2sram;
	wire arvalid_xbar2sram;
	wire arready_xbar2sram;

	wire [31:0] rdata_xbar2sram;
	wire [1:0] rresp_xbar2sram;
	wire rvalid_xbar2sram;
	wire rready_xbar2sram;

	wire [31:0] awaddr_xbar2sram;
	wire awvalid_xbar2sram;
	wire awready_xbar2sram;

	wire [31:0] wdata_xbar2sram;
	wire [3:0] wstrb_xbar2sram;
	wire wvalid_xbar2sram;
	wire wready_xbar2sram;

	wire [1:0] bresp_xbar2sram;
	wire bvalid_xbar2sram;
	wire bready_xbar2sram;
	
	// Xbar -> UART
	wire [31:0] araddr_xbar2uart;
	wire arvalid_xbar2uart;
	wire arready_xbar2uart;

	wire [31:0] rdata_xbar2uart;
	wire [1:0] rresp_xbar2uart;
	wire rvalid_xbar2uart;
	wire rready_xbar2uart;

	wire [31:0] awaddr_xbar2uart;
	wire awvalid_xbar2uart;
	wire awready_xbar2uart;

	wire [31:0] wdata_xbar2uart;
	wire [3:0] wstrb_xbar2uart;
	wire wvalid_xbar2uart;
	wire wready_xbar2uart;

	wire [1:0] bresp_xbar2uart;
	wire bvalid_xbar2uart;
	wire bready_xbar2uart;

	ysyx_23060061 CPU(
		.clock(clock),
		.reset(reset),
		
		.io_interrupt(),
		.io_master_awready(awready_cpu2xbar),
		.io_master_awvalid(awvalid_cpu2xbar),
		.io_master_awaddr(awaddr_cpu2xbar),
		.io_master_awid(),
		.io_master_awlen(),
		.io_master_awsize(),
		.io_master_awburst(),
		.io_master_wready(wready_cpu2xbar),
		.io_master_wvalid(wvalid_cpu2xbar),
		.io_master_wdata(wdata_cpu2xbar),
		.io_master_wstrb(wstrb_cpu2xbar),
		.io_master_wlast(),
		.io_master_bready(bready_cpu2xbar),
		.io_master_bvalid(bvalid_cpu2xbar),
		.io_master_bresp(bresp_cpu2xbar),
		.io_master_bid(),
		.io_master_arready(arready_cpu2xbar),
		.io_master_arvalid(arvalid_cpu2xbar),
		.io_master_araddr(araddr_cpu2xbar),
		.io_master_arid(),
		.io_master_arlen(),
		.io_master_arsize(),
		.io_master_arburst(),
		.io_master_rready(rready_cpu2xbar),
		.io_master_rvalid(rvalid_cpu2xbar),
		.io_master_rresp(rresp_cpu2xbar),
		.io_master_rdata(rdata_cpu2xbar),
		.io_master_rlast(),
		.io_master_rid(),

		.io_slave_awready(),
		.io_slave_awvalid(),
		.io_slave_awaddr(),
		.io_slave_awid(),
		.io_slave_awlen(),
		.io_slave_awsize(),
		.io_slave_awburst(),
		.io_slave_wready(),
		.io_slave_wvalid(),
		.io_slave_wdata(),
		.io_slave_wstrb(),
		.io_slave_wlast(),
		.io_slave_bready(),
		.io_slave_bvalid(),
		.io_slave_bresp(),
		.io_slave_bid(),
		.io_slave_arready(),
		.io_slave_arvalid(),
		.io_slave_araddr(),
		.io_slave_arid(),
		.io_slave_arlen(),
		.io_slave_arsize(),
		.io_slave_arburst(),
		.io_slave_rready(),
		.io_slave_rvalid(),
		.io_slave_rresp(),
		.io_slave_rdata(),
		.io_slave_rlast(),
		.io_slave_rid()
	);

	ysyx_23060061_XBar xbar(
		.clk            ( clock          ),
		.rst			( ~reset         ),
		.araddr      	( araddr_cpu2xbar       ),
		.arvalid     	( arvalid_cpu2xbar      ),
		.arready     	( arready_cpu2xbar      ),
		.rdata       	( rdata_cpu2xbar[31:0]        ),
		.rresp       	( rresp_cpu2xbar        ),
		.rvalid      	( rvalid_cpu2xbar       ),
		.rready      	( rready_cpu2xbar       ),
		.awaddr      	( awaddr_cpu2xbar       ),
		.awvalid     	( awvalid_cpu2xbar      ),
		.awready     	( awready_cpu2xbar      ),
		.wdata       	( wdata_cpu2xbar[31:0]        ),
		.wstrb       	( wstrb_cpu2xbar[3:0]        ),
		.wvalid      	( wvalid_cpu2xbar       ),
		.wready      	( wready_cpu2xbar       ),
		.bresp       	( bresp_cpu2xbar        ),
		.bvalid      	( bvalid_cpu2xbar       ),
		.bready      	( bready_cpu2xbar       ),

		.sram_araddr    ( araddr_xbar2sram),
		.sram_arvalid   ( arvalid_xbar2sram),
		.sram_arready   ( arready_xbar2sram),
		.sram_rdata     ( rdata_xbar2sram),
		.sram_rresp     ( rresp_xbar2sram),
		.sram_rvalid    ( rvalid_xbar2sram),
		.sram_rready    ( rready_xbar2sram),
		.sram_awaddr    ( awaddr_xbar2sram),
		.sram_awvalid   ( awvalid_xbar2sram),
		.sram_awready   ( awready_xbar2sram),
		.sram_wdata     ( wdata_xbar2sram),
		.sram_wstrb     ( wstrb_xbar2sram),
		.sram_wvalid    ( wvalid_xbar2sram),
		.sram_wready    ( wready_xbar2sram),
		.sram_bresp     ( bresp_xbar2sram),
		.sram_bvalid    ( bvalid_xbar2sram),
		.sram_bready    ( bready_xbar2sram),

		.uart_araddr    ( araddr_xbar2uart),
		.uart_arvalid   ( arvalid_xbar2uart),
		.uart_arready   ( arready_xbar2uart),
		.uart_rdata     ( rdata_xbar2uart),
		.uart_rresp     ( rresp_xbar2uart),
		.uart_rvalid    ( rvalid_xbar2uart),
		.uart_rready    ( rready_xbar2uart),
		.uart_awaddr    ( awaddr_xbar2uart),
		.uart_awvalid   ( awvalid_xbar2uart),
		.uart_awready   ( awready_xbar2uart),
		.uart_wdata     ( wdata_xbar2uart),
		.uart_wstrb     ( wstrb_xbar2uart),
		.uart_wvalid    ( wvalid_xbar2uart),
		.uart_wready    ( wready_xbar2uart),
		.uart_bresp     ( bresp_xbar2uart),
		.uart_bvalid    ( bvalid_xbar2uart),
		.uart_bready    ( bready_xbar2uart),

		.clint_araddr    ( araddr_xbar2clint),
		.clint_arvalid   ( arvalid_xbar2clint),
		.clint_arready   ( arready_xbar2clint),
		.clint_rdata     ( rdata_xbar2clint),
		.clint_rresp     ( rresp_xbar2clint),
		.clint_rvalid    ( rvalid_xbar2clint),
		.clint_rready    ( rready_xbar2clint),
		.clint_awaddr    ( awaddr_xbar2clint),
		.clint_awvalid   ( awvalid_xbar2clint),
		.clint_awready   ( awready_xbar2clint),
		.clint_wdata     ( wdata_xbar2clint),
		.clint_wstrb     ( wstrb_xbar2clint),
		.clint_wvalid    ( wvalid_xbar2clint),
		.clint_wready    ( wready_xbar2clint),
		.clint_bresp     ( bresp_xbar2clint),
		.clint_bvalid    ( bvalid_xbar2clint),
		.clint_bready    ( bready_xbar2clint)
	);

	ysyx_23060061_UART uart(
		.clk     	( clock     ),
		.rst     	( ~reset      ),
		.araddr  	( araddr_xbar2uart   ),
		.arvalid 	( arvalid_xbar2uart  ),
		.arready 	( arready_xbar2uart  ),
		.rdata   	( rdata_xbar2uart    ),
		.rresp   	( rresp_xbar2uart    ),
		.rvalid  	( rvalid_xbar2uart   ),
		.rready  	( rready_xbar2uart   ),
		.awaddr  	( awaddr_xbar2uart   ),
		.awvalid 	( awvalid_xbar2uart  ),
		.awready 	( awready_xbar2uart  ),
		.wdata   	( wdata_xbar2uart    ),
		.wstrb   	( wstrb_xbar2uart    ),
		.wvalid  	( wvalid_xbar2uart   ),
		.wready  	( wready_xbar2uart   ),
		.bresp   	( bresp_xbar2uart    ),
		.bvalid  	( bvalid_xbar2uart   ),
		.bready  	( bready_xbar2uart   )
	);
	
	ysyx_23060061_CLINT clint(
		.clk     	( clock      ),
		.rst     	( ~reset      ),
		.araddr  	( araddr_xbar2clint   ),
		.arvalid 	( arvalid_xbar2clint  ),
		.arready 	( arready_xbar2clint  ),
		.rdata   	( rdata_xbar2clint    ),
		.rresp   	( rresp_xbar2clint    ),
		.rvalid  	( rvalid_xbar2clint   ),
		.rready  	( rready_xbar2clint   ),
		.awaddr  	( awaddr_xbar2clint   ),
		.awvalid 	( awvalid_xbar2clint  ),
		.awready 	( awready_xbar2clint  ),
		.wdata   	( wdata_xbar2clint    ),
		.wstrb   	( wstrb_xbar2clint    ),
		.wvalid  	( wvalid_xbar2clint   ),
		.wready  	( wready_xbar2clint   ),
		.bresp   	( bresp_xbar2clint    ),
		.bvalid  	( bvalid_xbar2clint   ),
		.bready  	( bready_xbar2clint   )
	);

	ysyx_23060061_SRAM SRAM(
		.clk(clock),
		.rst(~reset), // reset of AXI is activate low

		.araddr(araddr_xbar2sram),
		.arvalid(arvalid_xbar2sram),
		.arready(arready_xbar2sram),

		.rdata(rdata_xbar2sram),
		.rresp(rresp_xbar2sram),
		.rvalid(rvalid_xbar2sram),
		.rready(rready_xbar2sram),

		.awaddr(awaddr_xbar2sram),
		.awvalid(awvalid_xbar2sram),
		.awready(awready_xbar2sram),

		.wdata(wdata_xbar2sram),
		.wstrb(wstrb_xbar2sram),
		.wvalid(wvalid_xbar2sram),
		.wready(wready_xbar2sram),

		.bresp(bresp_xbar2sram),
		.bvalid(bvalid_xbar2sram),
		.bready(bready_xbar2sram)
	);
endmodule