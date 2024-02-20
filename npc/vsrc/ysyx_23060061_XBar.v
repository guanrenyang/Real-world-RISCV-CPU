module ysyx_23060061_XBar (
	input clk,
	input rst,

	// input signals
	input [31:0] araddr,
	input arvalid,
	output arready,

	output [31:0] rdata,
	output [1:0] rresp,
	output rvalid,
	input rready,

	input [31:0] awaddr,
	input awvalid,
	output awready,

	input [31:0] wdata,
	input [3:0] wstrb,
	input wvalid,
	output wready,

	output [1:0] bresp,
	output bvalid,
	input bready,

	// output for SRAM
	output [31:0] sram_araddr,
	output sram_arvalid,
	input sram_arready,

	input [31:0] sram_rdata,
	input [1:0] sram_rresp,
	input sram_rvalid,
	output sram_rready,

	output [31:0] sram_awaddr,
	output sram_awvalid,
	input sram_awready,

	output [31:0] sram_wdata,
	output [3:0] sram_wstrb,
	output sram_wvalid,
	input sram_wready,

	input [1:0] sram_bresp,
	input sram_bvalid,
	output sram_bready,

	// output for UART
	output [31:0] uart_araddr,
	output uart_arvalid,
	input uart_arready,

	input [31:0] uart_rdata,
	input [1:0] uart_rresp,
	input uart_rvalid,
	output uart_rready,

	output [31:0] uart_awaddr,
	output uart_awvalid,
	input uart_awready,

	output [31:0] uart_wdata,
	output [3:0] uart_wstrb,
	output uart_wvalid,
	input uart_wready,

	input [1:0] uart_bresp,
	input uart_bvalid,
	output uart_bready,

	// output for CLINT
	output [31:0] clint_araddr,
	output clint_arvalid,
	input clint_arready,

	input [31:0] clint_rdata,
	input [1:0] clint_rresp,
	input clint_rvalid,
	output clint_rready,

	output [31:0] clint_awaddr,
	output clint_awvalid,
	input clint_awready,

	output [31:0] clint_wdata,
	output [3:0] clint_wstrb,
	output clint_wvalid,
	input clint_wready,

	input [1:0] clint_bresp,
	input clint_bvalid,
	output clint_bready
);

	reg [1:0] state;
	localparam IDLE = 2'b00;
	localparam UART = 2'b01;
	localparam SRAM = 2'b10;
	localparam CLINT = 2'b11;

	// serial logic
	always @(posedge clk) begin
		if (~rst) begin
			state <= IDLE;
		end else begin
			case (state) 
				IDLE: begin
					if (awvalid && wvalid) begin // When writing
						if (awaddr == `ysyx_23060061_SERIAL_MMIO) begin
							state <= UART;
						end else begin
							state <= SRAM;
						end
					end
					if (arvalid) begin // When reading
						if (araddr == `ysyx_23060061_RTC_MMIO || araddr == (`ysyx_23060061_RTC_MMIO + 4)) begin
							state <= CLINT;
						end else begin
							state <= SRAM;
						end
					end
				end
				SRAM: begin
					if (sram_rvalid && sram_rready) begin
						state <= IDLE;
					end
					if (sram_bvalid && sram_bready) begin
						state <= IDLE;
					end
				end
				UART: begin
					if (uart_bvalid && uart_bvalid) begin
						state <= IDLE;
					end
				end
				CLINT: begin
					if (clint_rvalid && clint_rready) begin
						state <= IDLE;
					end
				end
			endcase
		end
	end
	
	ysyx_23060061_MuxKey #(4,2,41) to_arbitrater(
		.out({arready, rdata, rresp, rvalid, awready, wready, bresp, bvalid}),
		.key(state),
		.lut({
			IDLE, {/*arready*/ 1'b0, /*rdata*/ 32'h00000000, /*rresp*/ 2'b00, /*rvalid*/ 1'b0, /*awready*/ 1'b0, /*wready*/ 1'b0, /*bresp*/ 2'b00, /*bvalid*/ 1'b0},
			SRAM, {/*arready*/ sram_arready, /*rdata*/ sram_rdata, /*rresp*/ sram_rresp, /*rvalid*/ sram_rvalid, /*awready*/ sram_awready, /*wready*/ sram_wready, /*bresp*/ sram_bresp, /*bvalid*/ sram_bvalid},
			UART, {/*arready*/ uart_arready, /*rdata*/ uart_rdata, /*rresp*/ uart_rresp, /*rvalid*/ uart_rvalid, /*awready*/ uart_awready, /*wready*/ uart_wready, /*bresp*/ uart_bresp, /*bvalid*/ uart_bvalid},
			CLINT, {/*arready*/ clint_arready, /*rdata*/ clint_rdata, /*rresp*/ clint_rresp, /*rvalid*/ clint_rvalid, /*awready*/ clint_awready, /*wready*/ clint_wready, /*bresp*/ clint_bresp, /*bvalid*/ clint_bvalid}
		})
	);
	
	ysyx_23060061_MuxKey #(4,2,105) to_sram(
		.out({sram_araddr, sram_arvalid, sram_rready, sram_awaddr, sram_awvalid, sram_wdata, sram_wstrb, sram_wvalid, sram_bready}),
		.key(state),
		.lut({
			IDLE, {/*sram_araddr*/ 32'h00000000, /*sram_arvalid*/ 1'b0, /*sram_rready*/ 1'b0, /*sram_awaddr*/ 32'h00000000, /*sram_awvalid*/ 1'b0, /*sram_wdata*/ 32'h00000000, /*sram_wstrb*/ 4'b0000, /*sram_wvalid*/ 1'b0, /*sram_bready*/ 1'b0},
			SRAM, {/*sram_araddr*/ araddr, /*sram_arvalid*/ arvalid, /*sram_rready*/ rready, /*sram_awaddr*/ awaddr, /*sram_awvalid*/ awvalid, /*sram_wdata*/ wdata, /*sram_wstrb*/ wstrb, /*sram_wvalid*/ wvalid, /*sram_bready*/ bready},
			UART, {/*sram_araddr*/ 32'h00000000, /*sram_arvalid*/ 1'b0, /*sram_rready*/ 1'b0, /*sram_awaddr*/ 32'h00000000, /*sram_awvalid*/ 1'b0, /*sram_wdata*/ 32'h00000000, /*sram_wstrb*/ 4'b0000, /*sram_wvalid*/ 1'b0, /*sram_bready*/ 1'b0},
			CLINT, {/*sram_araddr*/ 32'h00000000, /*sram_arvalid*/ 1'b0, /*sram_rready*/ 1'b0, /*sram_awaddr*/ 32'h00000000, /*sram_awvalid*/ 1'b0, /*sram_wdata*/ 32'h00000000, /*sram_wstrb*/ 4'b0000, /*sram_wvalid*/ 1'b0, /*sram_bready*/ 1'b0}
		})
	);

	ysyx_23060061_MuxKey #(4,2,105) to_uart(
		.out({uart_araddr, uart_arvalid, uart_rready, uart_awaddr, uart_awvalid, uart_wdata, uart_wstrb, uart_wvalid, uart_bready}),
		.key(state),
		.lut({
			IDLE, {/*uart_araddr*/ 32'h00000000, /*uart_arvalid*/ 1'b0, /*uart_rready*/ 1'b0, /*uart_awaddr*/ 32'h00000000, /*uart_awvalid*/ 1'b0, /*uart_wdata*/ 32'h00000000, /*uart_wstrb*/ 4'b0000, /*uart_wvalid*/ 1'b0, /*uart_bready*/ 1'b0},
			SRAM, {/*uart_araddr*/ 32'h00000000, /*uart_arvalid*/ 1'b0, /*uart_rready*/ 1'b0, /*uart_awaddr*/ 32'h00000000, /*uart_awvalid*/ 1'b0, /*uart_wdata*/ 32'h00000000, /*uart_wstrb*/ 4'b0000, /*uart_wvalid*/ 1'b0, /*uart_bready*/ 1'b0},
			UART, {/*uart_araddr*/ araddr, /*uart_arvalid*/ arvalid, /*uart_rready*/ rready, /*uart_awaddr*/ awaddr, /*uart_awvalid*/ awvalid, /*uart_wdata*/ wdata, /*uart_wstrb*/ wstrb, /*uart_wvalid*/ wvalid, /*uart_bready*/ bready},
			CLINT, {/*uart_araddr*/ 32'h00000000, /*uart_arvalid*/ 1'b0, /*uart_rready*/ 1'b0, /*uart_awaddr*/ 32'h00000000, /*uart_awvalid*/ 1'b0, /*uart_wdata*/ 32'h00000000, /*uart_wstrb*/ 4'b0000, /*uart_wvalid*/ 1'b0, /*uart_bready*/ 1'b0}
		})
	);

	ysyx_23060061_MuxKey #(4,2,105) to_clint(
		.out({clint_araddr, clint_arvalid, clint_rready, clint_awaddr, clint_awvalid, clint_wdata, clint_wstrb, clint_wvalid, clint_bready}),
		.key(state),
		.lut({
			IDLE, {/*clint_araddr*/ 32'h00000000, /*clint_arvalid*/ 1'b0, /*clint_rready*/ 1'b0, /*clint_awaddr*/ 32'h00000000, /*clint_awvalid*/ 1'b0, /*clint_wdata*/ 32'h00000000, /*clint_wstrb*/ 4'b0000, /*clint_wvalid*/ 1'b0, /*clint_bready*/ 1'b0},
			SRAM, {/*clint_araddr*/ 32'h00000000, /*clint_arvalid*/ 1'b0, /*clint_rready*/ 1'b0, /*clint_awaddr*/ 32'h00000000, /*clint_awvalid*/ 1'b0, /*clint_wdata*/ 32'h00000000, /*clint_wstrb*/ 4'b0000, /*clint_wvalid*/ 1'b0, /*clint_bready*/ 1'b0},
			CLINT, {/*clint_araddr*/ araddr, /*clint_arvalid*/ arvalid, /*clint_rready*/ rready, /*clint_awaddr*/ awaddr, /*clint_awvalid*/ awvalid, /*clint_wdata*/ wdata, /*clint_wstrb*/ wstrb, /*clint_wvalid*/ wvalid, /*clint_bready*/ bready},
			UART, {/*clint_araddr*/ 32'h00000000, /*clint_arvalid*/ 1'b0, /*clint_rready*/ 1'b0, /*clint_awaddr*/ 32'h00000000, /*clint_awvalid*/ 1'b0, /*clint_wdata*/ 32'h00000000, /*clint_wstrb*/ 4'b0000, /*clint_wvalid*/ 1'b0, /*clint_bready*/ 1'b0}
		})
	);

endmodule