module ysyx_23060061_SRAM(
	// A SRAM which supports AXI-Lite interface
	input clk,
	input rst, // low active

	input [31:0] araddr,
	input arvalid,
	output reg arready,

	output reg [31:0] rdata,
	output reg [1:0] rresp,
	output reg rvalid,
	input rready,

	input [31:0] awaddr,
	input awvalid,
	output awready,

	input [31:0] wdata,
	input [3:0] wstrb,
	input wvalid,
	output wready,

	output bresp,
	output reg bvalid,
	input bready
);
	parameter LISTEN_ADDR = 0;
	parameter FEED_DATA = 1;
	parameter WAIT_RECEIVE = 2;
	
	reg [1:0] state;
	
	reg [31:0] raddr;
	wire [31:0] rdata_internal;
	always @(raddr) begin
		if (state == FEED_DATA)
			paddr_read(raddr, rdata_internal);
	end
	
	always @(posedge clk) begin
		if (~rst) begin
			state <= LISTEN_ADDR; // state transition

			// rvalid and bvalid must be set to 0 when reset is asserted
			rvalid <= 0;
			bvalid <= 0;	

			arready <= 1; // ready to receive address just after the cycle when reset is deasserted
		end else begin
			case (state)
				LISTEN_ADDR: begin
					if (arvalid && arready) begin
						state <= FEED_DATA; // state transition
						arready <= 0; // start feeding data and stop receiving address

						raddr <= araddr; // store the araddr because reading data may take serval cycles
					end
				end
				FEED_DATA: begin
					state <= WAIT_RECEIVE; // state transition
					// Now SRAM can feed data in one cycle
					rvalid <= 1;
					rdata <= rdata_internal;
					rresp <= 2'b00; // OKAY
				end
				WAIT_RECEIVE: begin
					if (rvalid && rready) begin
						state <= LISTEN_ADDR; // state transition
						rvalid <= 0; // stop feeding data
						arready <= 1; // ready to receive address
					end
				end
			endcase
		end
	end
endmodule
