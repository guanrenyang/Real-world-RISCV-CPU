module ysyx_23060061_UART (
	input clk,
	input rst, // low activate

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
	reg [1:0] state;
	localparam LISTEN_ADDR = 0;	
	localparam WRITE_DATA = 1;
	localparam WAIT_RESP = 2;
	
	// Internal signals to store the address and data
	reg [31:0] waddr_internal;
	reg [3:0] wstrb_internal;
	reg [31:0] wdata_internal;
	
	// Display data through DPI-C
	wire [31:0] rdata_internal;
	always @(waddr_internal or wstrb_internal or wdata_internal) begin
		if (state == WRITE_DATA) begin
			uart_display(waddr_internal, wdata_internal & 32'h000000ff);
		end
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

			arready <= 0; // Read is not supported in UART 

			awready <= 1;
			wready <= 1;
		end else begin
			case (state)
				LISTEN_ADDR: begin
					if (delay_trigger) begin
						awready <= 1;
						wready <= 1;
					end
					if(awvalid && awready && wvalid && wready) begin
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
				WRITE_DATA: begin
					if (delay_trigger) begin
						state <= WAIT_RESP; // state transition
						// NART can print data in one cycle
						bvalid <= 1;
						bresp <= 2'b00; // OKAY
					end
				end
				WAIT_RESP: begin
					if (bvalid && bready) begin
						state <= LISTEN_ADDR; // state transition
						bvalid <= 0; // stop writing data

						waddr_internal <= 0;
						wdata_internal <= 0;
						wstrb_internal <= 0;
					end
				end
			endcase
		end
	end
endmodule