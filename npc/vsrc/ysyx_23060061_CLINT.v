module ysyx_23060061_CLINT (
	input clk,
	input rst, // low activate

	input [31:0] araddr,
	input arvalid,
	output reg arready,
	input [3:0] arid, // AXI4
	input [7:0] arlen, // AXI4
	input [2:0] arsize, // AXI4
	input [1:0] arburst, // AXI4

	output reg [31:0] rdata,
	output reg [1:0] rresp,
	output reg rvalid,
	input rready,
	output reg rlast, // AXI4
	output reg [3:0] rid, // AXI4

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
	// time counter
	reg [31:0] mtime_low;
	reg [31:0] mtime_high;

	// sequencial logic for mtime 
	always @(posedge clk) begin
		if(~rst) begin
			mtime_high <= 0;
			mtime_low <= 0;
		end else begin
			mtime_low <= mtime_low + 1;
			mtime_high <= mtime_high + {31'd0, (mtime_low == 32'hFFFFFFFF)};
		end
	end

	// FSM
	reg [1:0] state;
	localparam LISTEN_ADDR = 0;	
	localparam FEED_DATA = 1;
	localparam WAIT_RECEIVE	= 2;

	// Internal signals to store the address and data
	reg [31:0] raddr;

	// DPI-C to access CLINT

	// Generate Random Delay
	wire delay_trigger;
	ysyx_23060061_RandomDelayGenerator randomDelayGenerator(
		.clk(clk),
		.rst(rst),
		.delay_trigger(delay_trigger)
	);

	// State Transition
	always @(posedge clk) begin 
		if(~rst) begin
			state <= LISTEN_ADDR;

			rvalid <= 0;
			bvalid <= 0;

			arready <= 1; // CLINT is read-only

			awready <= 0;
			wready <= 0;
		end else begin
			case (state)
				LISTEN_ADDR: begin
					if (delay_trigger) begin
						arready <= 1;
					end
					if (arvalid && arready) begin
						state <= FEED_DATA;
						arready <= 0;

						raddr <= araddr;
					end
				end
				FEED_DATA: begin
					if (delay_trigger) begin
						state <= WAIT_RECEIVE;

						rvalid <= 1;
						rdata <= raddr == `ysyx_23060061_RTC_MMIO ? mtime_low : mtime_high; // TODO: Check address boundary
						rresp <= 2'b00; // OKAY
					end
				end
				WAIT_RECEIVE: begin
					if (rvalid && rready) begin
						state <= LISTEN_ADDR;
						rvalid <= 0;

						raddr <= 0;
					end
				end
			endcase
		end
	end
	
endmodule