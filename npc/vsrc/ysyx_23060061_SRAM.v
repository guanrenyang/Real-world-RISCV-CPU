module ysyx_23060061_SRAM(
	// A SRAM which supports AXI-Lite interface
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
	input [3:0] awid, // AXI4
	input [7:0] awlen, // AXI4
	input [2:0] awsize, // AXI4
	input [1:0] awburst, // AXI4
	output reg awready,

	input [31:0] wdata,
	input [3:0] wstrb,
	input wvalid,
	input wlast, // AXI4
	output reg wready,

	output reg [1:0] bresp,
	output reg bvalid,
	output reg [3:0] bid, // AXI4
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
	// Read
	reg [31:0] raddr;
	reg [3:0] arid_internal;
	reg [7:0] arlen_internal;
	reg [2:0] arsize_internal;
	reg [1:0] arburst_internal;

	// Write
	reg [3:0] awid_internal;
	reg [7:0] awlen_internal;
	reg [2:0] awsize_internal;
	reg [1:0] awburst_internal;
	reg [31:0] waddr_internal;
	reg [3:0] wstrb_internal;
	reg [31:0] wdata_internal;
	reg wlast_internal;
	
	// ByteSel_read signal for narrow read
	wire [1:0] ByteSel_read;
	assign ByteSel_read = raddr[1:0];

	// ByteSel_Write Signal for narrow write
	
	// DPI-C to access SRAM
	wire [31:0] rdata_internal;
	always @(raddr) begin
		if (state == FEED_DATA)
			paddr_read(raddr, rdata_internal, {29'd0, arsize_internal}, {30'd0, ByteSel_read});
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
						arid_internal <= arid;
						arlen_internal <= arlen;
						arsize_internal <= arsize;
						arburst_internal <= arburst;
					end
					if (awvalid && awready && wvalid && wready) begin
						state <= WRITE_DATA; // state transition
						
						// start writing data and stop receiving address
						awready <= 0; 
						wready <= 0;
						// store the waddr and wdata 
						awid_internal <= awid;
						awlen_internal <= awlen;
						awsize_internal <= awsize;
						awburst_internal <= awburst;
						
						waddr_internal <= awaddr;
						wdata_internal <= wdata;
						wstrb_internal <= wstrb;
						wlast_internal <= wlast;
					end
				end
				FEED_DATA: begin
					if (delay_trigger) begin
						if (arlen == 8'b00000000) begin // read 4 bytes in a burst at a time
							// $display("ARSIZE: %d", arsize);
    						state <= WAIT_RECEIVE; // state transition
    						// Now SRAM can feed data in one cycle
    						rvalid <= 1;
    						rdata <= rdata_internal;
    						rresp <= 2'b00; // OKAY
							rlast <= 1;
							rid <= arid_internal;
						end else begin
							$display("Error: SRAM does not support the read request");
							$finish;
							// state <= LISTEN_ADDR;
							// rresp <= 2'b10; // SLVERR
							// rvalid <= 1;
						end
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
						if(awlen_internal == 8'b00000000 && awburst_internal == 2'b01) begin // write 4 bytes in a burst at a time
							// $display("AWSIZE: %d", awsize_internal);
							state <= WAIT_RESP; // state transition
							// Now SRAM can write data in one cycle
							bvalid <= 1;
							bid <= awid_internal;
							bresp <= 2'b00; // OKAY
						end else begin
							$display("Error: SRAM does not support the write request");
							$finish;
						end
					end
				end
				WAIT_RESP: begin
					if(bvalid && bready) begin
						state <= LISTEN_ADDR; // state transition
						bvalid <= 0; // stop writing data
						// awready <= 1; // ready to receive address
						// wready <= 1;
						awid_internal <= 0;
						awlen_internal <= 0;
						awsize_internal <= 0;	
						awburst_internal <= 0;
						
						waddr_internal <= 0;
						wdata_internal <= 0;
						wstrb_internal <= 0;
						wlast_internal <= 0;
					end
				end
			endcase
		end
	end
endmodule
