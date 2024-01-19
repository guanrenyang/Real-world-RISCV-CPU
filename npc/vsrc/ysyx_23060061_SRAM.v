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
	output reg awready,

	input [31:0] wdata,
	input [3:0] wstrb,
	input wvalid,
	output reg wready,

	output reg [1:0] bresp,
	output reg bvalid,
	input bready
);
	// FSM
	reg [2:0] state;
	localparam LISTEN_ADDR = 0;
	localparam FEED_DATA = 1;
	localparam WAIT_RECEIVE = 2;
	localparam WRITE_DATA = 3;	
	localparam WAIT_RESP = 4;

	// Internal signals to store the address and data
	reg [31:0] raddr;
	reg [31:0] waddr_internal;
	reg [3:0] wstrb_internal;
	reg [31:0] wdata_internal;
	
	// DPI-C to access SRAM
	wire [31:0] rdata_internal;
	always @(raddr) begin
		if (state == FEED_DATA)
			paddr_read(raddr, rdata_internal);
	end
	always @(waddr_internal or wstrb_internal or wdata_internal) begin
		if (state == WRITE_DATA)
			paddr_write(waddr_internal, wdata_internal, {4'b0000, wstrb_internal});
	end
	
	// Generate Random Delay
	wire delay_trigger;
	ysyx_23060061_RandomDelayGenerator randomDelayGenerator(
		.clk(clk),
		.rst(rst),
		.delay_trigger(delay_trigger)
	);

	// State Transition
	always @(posedge clk) begin
		if (~rst) begin
			state <= LISTEN_ADDR; // state transition

			// rvalid and bvalid must be set to 0 when reset is asserted
			rvalid <= 0;
			bvalid <= 0;	

			arready <= 1; // ready to receive address just after the cycle when reset is deasserted

			awready <= 1;
			wready <= 1;
		end else begin
			case (state)
				LISTEN_ADDR: begin
					if (delay_trigger) begin
						arready <= 1; // ready to receive address just after the cycle when reset is deasserted
						awready <= 1;
						wready <= 1;
					end
					if (arvalid && arready) begin
						state <= FEED_DATA; // state transition
						arready <= 0; // start feeding data and stop receiving address

						raddr <= araddr; // store the araddr because reading data may take serval cycles
					end
					if (awvalid && awready && wvalid && awready) begin
						state <= WRITE_DATA; // state transition
						
						// start writing data and stop receiving address
						awready <= 0; 
						wready <= 0;
						// store the waddr and wdata 
						waddr_internal <= awaddr;
						wdata_internal <= wdata;
						wstrb_internal <= wstrb;
					end
				end
				FEED_DATA: begin
					if (delay_trigger) begin
    					state <= WAIT_RECEIVE; // state transition
    					// Now SRAM can feed data in one cycle
    					rvalid <= 1;
    					rdata <= rdata_internal;
    					rresp <= 2'b00; // OKAY
					end
				end
				WAIT_RECEIVE: begin
					if (rvalid && rready) begin
						state <= LISTEN_ADDR; // state transition
						rvalid <= 0; // stop feeding data
						// arready <= 1; // ready to receive address
						
						raddr <= 0;
					end
				end

				WRITE_DATA: begin
					if (delay_trigger) begin
						state <= WAIT_RESP; // state transition
						// Now SRAM can write data in one cycle
						bvalid <= 1;
						bresp <= 2'b00; // OKAY
					end
				end
				WAIT_RESP: begin
					if(bvalid && bready) begin
						state <= LISTEN_ADDR; // state transition
						bvalid <= 0; // stop writing data
						// awready <= 1; // ready to receive address
						// wready <= 1;
						
						waddr_internal <= 0;
						wdata_internal <= 0;
						wstrb_internal <= 0;
					end
				end
			endcase
		end
	end
endmodule
