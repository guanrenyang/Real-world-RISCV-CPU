module ysyx_23060061_AXILiteArbitrater(
	input clk,
	input rst,

	// output singals
	output [31:0] araddr,
	output arvalid,
	input arready,

	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output rready,

	output [31:0] awaddr,
	output awvalid,
	input awready,

	output [31:0] wdata,
	output [3:0] wstrb,
	output wvalid,
	input wready,

	input [1:0] bresp,
	input bvalid,
	output bready,

	// input from ifu
	input [31:0] ifu_araddr,
	input ifu_arvalid,
	output ifu_arready,

	output [31:0] ifu_rdata,
	output [1:0] ifu_rresp,
	output ifu_rvalid,
	input ifu_rready,

	input [31:0] ifu_awaddr,
	input ifu_awvalid,
	output ifu_awready,

	input [31:0] ifu_wdata,
	input [3:0] ifu_wstrb,
	input ifu_wvalid,
	output ifu_wready,

	output [1:0] ifu_bresp,
	output ifu_bvalid,
	input ifu_bready,

	// input from lsu
	input [31:0] lsu_araddr,
	input lsu_arvalid,
	output lsu_arready,

	output [31:0] lsu_rdata,
	output [1:0] lsu_rresp,
	output lsu_rvalid,
	input lsu_rready,

	input [31:0] lsu_awaddr,
	input lsu_awvalid,
	output lsu_awready,

	input [31:0] lsu_wdata,
	input [3:0] lsu_wstrb,
	input lsu_wvalid,
	output lsu_wready,

	output [1:0] lsu_bresp,
	output lsu_bvalid,
	input lsu_bready
);
	localparam [1:0] IDLE = 2'b00;
	localparam [1:0] SERVE_IFU = 2'b01;
	localparam [1:0] SERVE_LSU = 2'b10;
	
	wire ifu_trigger = ifu_arvalid | (ifu_awvalid & ifu_wvalid);
	wire lsu_trigger = lsu_arvalid | (lsu_awvalid & lsu_wvalid);
	wire exit = rready | bready;
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
	ysyx_23060061_MuxKeyWithDefault #(2, 2, 104) mux_arbitarter_to_sram(
		.out({araddr, arvalid, awaddr, awvalid, wdata, wstrb, wvalid, bready}),
		.key(state),
		.default_out(0),
		.lut({
			SERVE_IFU, {ifu_araddr, ifu_arvalid, ifu_awaddr, ifu_awvalid, ifu_wdata, ifu_wstrb, ifu_wvalid, ifu_bready},
			SERVE_LSU, {lsu_araddr, lsu_arvalid, lsu_awaddr, lsu_awvalid, lsu_wdata, lsu_wstrb, lsu_wvalid, lsu_bready}
		})
	);
	ysyx_23060061_MuxKeyWithDefault #(1, 2, 41) mux_arbitarter_from_sram_to_ifu(
		.out({ifu_arready, ifu_rdata, ifu_rresp, ifu_rvalid, ifu_awready, ifu_wready, ifu_bresp, ifu_bvalid}),
		.key(state),
		.default_out(0),
		.lut({
			SERVE_IFU, {arready, rdata, rresp, rvalid, awready, wready, bresp, bvalid}
		})
	);
	ysyx_23060061_MuxKeyWithDefault #(1, 2, 41) mux_arbitarter_from_sram_to_lsu(
		.out({lsu_arready, lsu_rdata, lsu_rresp, lsu_rvalid, lsu_awready, lsu_wready, lsu_bresp, lsu_bvalid}),
		.key(state),
		.default_out(0),
		.lut({
			SERVE_LSU, {arready, rdata, rresp, rvalid, awready, wready, bresp, bvalid}
		})
	);
endmodule