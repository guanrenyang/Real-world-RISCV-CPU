// module ysyx_23060061_UART (
// 	input clk,
// 	input rst, // low activate
//
// 	input [31:0] araddr,
// 	input arvalid,
// 	output reg arready,
//
// 	output reg [31:0] rdata,
// 	output reg [1:0] rresp,
// 	output reg rvalid,
// 	input rready,
//
// 	input [31:0] awaddr,
// 	input awvalid,
// 	output reg awready,
//
// 	input [31:0] wdata,
// 	input [3:0] wstrb,
// 	input wvalid,
// 	output reg wready,
//
// 	output reg [1:0] bresp,
// 	output reg bvalid,
// 	input bready
// );
// 	// FSM
// 	reg [1:0] state;
// 	localparam LISTEN_ADDR = 0;	
// 	localparam WRITE_DATA = 1;
// 	localparam WAIT_RESP = 2;
// 	
// 	// Internal signals to store the address and data
// 	reg [31:0] waddr_internal;
// 	reg [3:0] wstrb_internal;
// 	reg [31:0] wdata_internal;
// 	
// 	// Generate Random Delay
// 	wire delay_trigger;
// 	ysyx_23060061_RandomDelayGenerator randomDelayGenerator(
// 		.clk(clk),
// 		.rst(rst),
// 		.delay_trigger(delay_trigger)
// 	); 
// 	
// 	// State Transition
// 	always @(posedge clk) begin
// 		if (~rst) begin
// 			state <= LISTEN_ADDR; // state transition
//
// 			// rvalid and bvalid must be set to 0 when reset is asserted
// 			rvalid <= 0;
// 			bvalid <= 0;	
//
// 			arready <= 0; // Read is not supported in UART 
//
// 			awready <= 1;
// 			wready <= 1;
// 		end else begin
// 			case (state)
// 				LISTEN_ADDR: begin
// 					if (delay_trigger) begin
// 						awready <= 1;
// 						wready <= 1;
// 					end
// 					if(awvalid && awready && wvalid && awready)
// 				end
// 			endcase
// 		end
// 	end
// endmodule