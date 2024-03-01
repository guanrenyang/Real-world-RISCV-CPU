module ysyx_23060061_AXILiteArbitrater(
	input clk,
	input rst,

	// output singals
	output [31:0] araddr,
	output arvalid,
	input arready,
	output [3:0] arid, // AXI4
	output [7:0] arlen, // AXI4
	output [2:0] arsize, // AXI4
	output [1:0] arburst, // AXI4

	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output rready,
	input rlast, // AXI4
	input [3:0] rid, // AXI4

	output [31:0] awaddr,
	output awvalid,
	output [3:0] awid, // AXI4
	output [7:0] awlen, // AXI4
	output [2:0] awsize, // AXI4
	output [1:0] awburst, // AXI4
	input awready,

	output [31:0] wdata,
	output [3:0] wstrb,
	output wvalid,
	output wlast, // AXI4
	input wready,

	input [1:0] bresp,
	input bvalid,
	input [3:0] bid, // AXI4
	output bready,

	// input from ifu
	input [31:0] ifu_araddr,
	input ifu_arvalid,
	output ifu_arready,
	input [3:0] ifu_arid, // AXI4
	input [7:0] ifu_arlen, // AXI4
	input [2:0] ifu_arsize, // AXI4
	input [1:0] ifu_arburst, // AXI4

	output [31:0] ifu_rdata,
	output [1:0] ifu_rresp,
	output ifu_rvalid,
	input ifu_rready,
	output ifu_rlast, // AXI4
	output [3:0] ifu_rid, // AXI4

	input [31:0] ifu_awaddr,
	input ifu_awvalid,
	input [3:0] ifu_awid, // AXI4
	input [7:0] ifu_awlen, // AXI4
	input [2:0] ifu_awsize, // AXI4
	input [1:0] ifu_awburst, // AXI4
	output ifu_awready,

	input [31:0] ifu_wdata,
	input [3:0] ifu_wstrb,
	input ifu_wvalid,
	input ifu_wlast, // AXI4
	output ifu_wready,

	output [1:0] ifu_bresp,
	output ifu_bvalid,
	output [3:0] ifu_bid, // AXI4
	input ifu_bready,

	// input from lsu
	input [31:0] lsu_araddr,
	input lsu_arvalid,
	output lsu_arready,
	input [3:0] lsu_arid, // AXI4
	input [7:0] lsu_arlen, // AXI4
	input [2:0] lsu_arsize, // AXI4
	input [1:0] lsu_arburst, // AXI4

	output [31:0] lsu_rdata,
	output [1:0] lsu_rresp,
	output lsu_rvalid,
	input lsu_rready,
	output lsu_rlast, // AXI4
	output [3:0] lsu_rid, // AXI4

	input [31:0] lsu_awaddr,
	input lsu_awvalid,
	input [3:0] lsu_awid, // AXI4
	input [7:0] lsu_awlen, // AXI4
	input [2:0] lsu_awsize, // AXI4
	input [1:0] lsu_awburst, // AXI
	output lsu_awready,

	input [31:0] lsu_wdata,
	input [3:0] lsu_wstrb,
	input lsu_wvalid,
	input lsu_wlast, // AXI4
	output lsu_wready,

	output [1:0] lsu_bresp,
	output lsu_bvalid,
	output [3:0] lsu_bid, // AXI4
	input lsu_bready
);
	localparam [1:0] IDLE = 2'b00;
	localparam [1:0] SERVE_IFU = 2'b01;
	localparam [1:0] SERVE_LSU = 2'b10;
	
	wire ifu_trigger = ifu_arvalid | (ifu_awvalid & ifu_wvalid);
	wire lsu_trigger = lsu_arvalid | (lsu_awvalid & lsu_wvalid);
	wire exit = ifu_rready | ifu_bready | lsu_rready | lsu_bready;
	reg [1:0] state;
	always @(posedge clk) begin
		if (~rst) begin
			state <= IDLE;
		end else begin
			case(state)
				IDLE: begin
					if (ifu_trigger) begin						
						state <= SERVE_IFU;
					end else if (lsu_trigger) begin
						state <= SERVE_LSU;
					end 
				end
				SERVE_IFU: begin
					if (exit) begin
						state <= IDLE;
					end
				end
				SERVE_LSU: begin
					if (exit) begin
						state <= IDLE;
					end
				end
				default: begin
					state <= IDLE;
				end
			endcase
		end
	end
	ysyx_23060061_MuxKeyWithDefault #(2, 2, 140) mux_arbitarter_to_sram(
		.out({araddr, arvalid, arid, arlen, arsize, arburst, rready, awaddr, awvalid, awid, awlen, awsize, awburst, wdata, wstrb, wvalid, wlast, bready}),
		.key(state),
		.default_out(0),
		.lut({
			SERVE_IFU, {ifu_araddr, ifu_arvalid, ifu_arid, ifu_arlen, ifu_arsize, ifu_arburst, ifu_rready, ifu_awaddr, ifu_awvalid, ifu_awid, ifu_awlen, ifu_awsize, ifu_awburst, ifu_wdata, ifu_wstrb, ifu_wvalid, ifu_wlast, ifu_bready},
			SERVE_LSU, {lsu_araddr, lsu_arvalid, lsu_arid, lsu_arlen, lsu_arsize, lsu_arburst, lsu_rready, lsu_awaddr, lsu_awvalid, lsu_awid, lsu_awlen, lsu_awsize, lsu_awburst, lsu_wdata, lsu_wstrb, lsu_wvalid, lsu_wlast, lsu_bready}
		})
	);
	ysyx_23060061_MuxKeyWithDefault #(1, 2, 50) mux_arbitarter_from_sram_to_ifu(
		.out({ifu_arready, ifu_rdata, ifu_rresp, ifu_rvalid, ifu_rlast, ifu_rid, ifu_awready, ifu_wready, ifu_bresp, ifu_bvalid, ifu_bid}),
		.key(state),
		.default_out(0),
		.lut({
			SERVE_IFU, {arready, rdata, rresp, rvalid, rlast, rid, awready, wready, bresp, bvalid, bid}
		})
	);
	ysyx_23060061_MuxKeyWithDefault #(1, 2, 50) mux_arbitarter_from_sram_to_lsu(
		.out({lsu_arready, lsu_rdata, lsu_rresp, lsu_rvalid, lsu_rlast, lsu_rid, lsu_awready, lsu_wready, lsu_bresp, lsu_bvalid, lsu_bid}),
		.key(state),
		.default_out(0),
		.lut({
			SERVE_LSU, {arready, rdata, rresp, rvalid, rlast, rid, awready, wready, bresp, bvalid, bid}
		})
	);
endmodule