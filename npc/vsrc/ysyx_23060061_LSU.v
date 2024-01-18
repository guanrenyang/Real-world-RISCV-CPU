module ysyx_23060061_LSU(
	input clk,
	input rst,

	input [2:0] memExt,
	input [1:0] MemRW,
	input [31:0] memAddr,
	input [31:0] memDataW,
	input [3:0] wmask,
	input exu_valid,
	output lsu_ready,
	
	output lsu_valid,
	input wbu_ready,
	output [31:0] memDataR,

	// signals for LSU->SRAM in AXI-Lite interface
	output reg [31:0] araddr,
	output reg arvalid,
	input arready,

	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output reg rready,

	output reg [31:0] awaddr,
	output reg awvalid,
	input awready,

	output reg [31:0] wdata,
	output reg [3:0] wstrb,
	output reg wvalid,
	input wready,

	input [1:0] bresp,
	input bvalid,
	output reg bready

);

	localparam IDLE = 0; // Do nothing
	localparam SEND_ADDR = 1; // IDLE->SEND_ADDR: when MemRW is 2'b10, pull high arvalid and araddr
	localparam WAIT_DATA = 2; // SEND_ADDR->WAIT_DATA: when arready is high, set low arvalid and pull high rready
	localparam WAIT_WBU = 3; // WAIT_DATA->WAIT_CPU: when rvalid is high, set rready low and pull lsu_valid high
							 // WAIT_CPU->IDLE: when &lsu_valid is high, set lsu_valid low and pull lsu_ready high
	localparam SEND_AWADDR_WDATA = 4;
	localparam WAIT_WRESP = 5;

	reg [2:0] state;

	reg memDataReady;
	assign lsu_valid = exu_valid & ( MemRW == 0 | memDataReady);
	assign lsu_ready = wbu_ready;

	reg [31:0] unextMemDataR; // Store the data read from DataMem
	always @(posedge clk) begin
		if (~rst) begin
			state <= IDLE;
			// signals for InstMem -- determined by AXI-Lite protocol
			arvalid <= 0;
			awvalid <= 0;
			wvalid <= 0;
			// internal signals
			unextMemDataR <= 0;
			memDataReady <= 0;
		end else begin
			case (state) 
				IDLE: begin
					if (exu_valid & MemRW[1]) begin // need to read DataMem
						state <= SEND_ADDR;

						assert (memDataReady == 0);// In IDLE state, memDataReady must be 0
						assert (lsu_valid == 0);
						
						arvalid <= 1;
						araddr <= memAddr;
						rready <= 0;
					end
					if (exu_valid && MemRW[0]) begin
						state <= SEND_AWADDR_WDATA;

						assert (memDataReady == 0);// In IDLE state, memDataReady must be 0
						assert (lsu_valid == 0);					
						
						awvalid <= 1;
						awaddr <= memAddr;	
						wvalid <= 1;
						wdata <= memDataW;
						wstrb <= wmask;

						bready <= 0;
					end
					memDataReady <= 0;
				end
				SEND_ADDR: begin
					if (arvalid && arready) begin
						state <= WAIT_DATA;

						arvalid <= 0;
						rready <= 1;
					end
				end
				WAIT_DATA: begin
					if (rvalid & rready) begin
						state <= WAIT_WBU;
						
						rready <= 0;
						unextMemDataR <= rdata;
						memDataReady <= 1;
					end
				end
				SEND_AWADDR_WDATA: begin
					if (awvalid && awready) begin
						state <= WAIT_WRESP;

						awvalid <= 0;
						wvalid <= 0;
						bready <= 1;
					end
				end
				WAIT_WRESP: begin
					if (bvalid && bready) begin
						state <= WAIT_WBU;

						bready <= 0;
						memDataReady <= 1;
					end
				end
				WAIT_WBU: begin
					if (wbu_ready) begin
						state <= IDLE;
						memDataReady <= 0;
					end
				end
			endcase				
		end
	end

    // wire [31:0] memDataR_internal;

	// Memory bit extension
	ysyx_23060061_MuxKey #(5, 3, 32) memDataR_ext(
		.out(memDataR),
		.key(memExt),
		.lut({
			3'b000, unextMemDataR,
			3'b001, {{24{unextMemDataR[7]}}, unextMemDataR[7:0]}, 3'b010, {{16{unextMemDataR[15]}}, unextMemDataR[15:0]}, 3'b011, {24'd0, unextMemDataR[7:0]},
			3'b100, {16'd0, unextMemDataR[15:0]}
		})
  	);

	// Memory read
  // 	always @(MemRW, memAddr, memDataW) begin
		// if (exu_valid) begin
  //   		if(MemRW==2'b10) begin
  //   			paddr_read(memAddr, unextMemDataR);
  //   		end else if (MemRW==2'b01) begin
  //   			paddr_write(memAddr, memDataW, {4'b0000, wmask});
  //   		end
		// end
  // 	end
  

  // 	always @(posedge clk) begin
		// if (~rst) begin
		// 	memDataR <= 0;
		// 	DataMemValid_internal <= 0;
		// end else begin
		// 	memDataR <= memDataR_internal;
		// 	DataMemValid_internal <= exu_valid & MemRW[1] & ~wbu_ready;
		// end
  // 	end

endmodule