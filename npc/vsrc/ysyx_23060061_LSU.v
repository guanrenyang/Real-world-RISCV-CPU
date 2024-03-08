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
	input [2:0] AxSIZE,

	// signals for LSU->SRAM in AXI-Lite interface
	output reg [31:0] araddr,
	output reg arvalid,
	input arready,
  	output reg [3:0] arid, // AXI4
  	output reg [7:0] arlen, // AXI4
  	output reg [2:0] arsize, // AXI4
  	output reg [1:0] arburst, // AXI4


	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output reg rready,
	input rlast, // AXI4
	input [3:0] rid, // AXI4

	output reg [31:0] awaddr,
	output reg awvalid,
	output reg [3:0] awid, // AXI4
	output reg [7:0] awlen, // AXI4
	output reg [2:0] awsize, // AXI4
	output reg [1:0] awburst, // AXI4
	input awready,

	output reg [31:0] wdata,
	output reg [3:0] wstrb,
	output reg wvalid,
	output reg wlast, // AXI4
	input wready,

	input [1:0] bresp,
	input bvalid,
	input [3:0] bid, // AXI4
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

	// Random delay generator
	wire delay_trigger;
	ysyx_23060061_RandomDelayGenerator randomDelayGenerator(
		.clk(clk),
		.rst(rst),
		.delay_trigger(delay_trigger)
	);

	wire [31:0] unextMemDataR; // Store the data shifted but not signed extended
	reg [31:0] unshftMemDataR; // Store the data directly read from DataMemA

	always @(posedge clk) begin
		if (~rst) begin
			state <= IDLE;
			// signals for InstMem -- determined by AXI-Lite protocol
			arvalid <= 0;
			awvalid <= 0;
			wvalid <= 0;
			// internal signals
			unshftMemDataR <= 0;
			memDataReady <= 0;
		end else begin
			case (state) 
				IDLE: begin
					if (exu_valid & MemRW[1] & delay_trigger) begin // need to read DataMem
						state <= SEND_ADDR;

						assert (memDataReady == 0);// In IDLE state, memDataReady must be 0
						assert (lsu_valid == 0);
					
						arvalid <= 1;
						araddr <= memAddr;
						arid <= 4'b0000; // one read at a time so id won't change
						arlen <= 8'b00000000; // one read in a burst
						arsize <= AxSIZE;
						arburst <= 2'b01; // increamenting burst
						rready <= 0;
					end
					if (exu_valid & MemRW[0] & delay_trigger) begin // write sram
						state <= SEND_AWADDR_WDATA;

						assert (memDataReady == 0);// In IDLE state, memDataReady must be 0
						assert (lsu_valid == 0);					
						
						awvalid <= 1;
						awaddr <= memAddr;	
						awid <= 4'b0000;
						awlen <= 8'b00000000; // one transfer in a burst
						awsize <= AxSIZE;
						awburst <= 2'b01; // increamenting burst

						wvalid <= 1;
						wlast <= 1;// one transfer in a burst
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
					end
				end
				WAIT_DATA: begin
					if (delay_trigger)
						rready <= 1;
					if (rvalid & rready) begin
						if (rresp == 2'b00 /*OKAY*/ && rid == arid && rlast) begin // finish read burst
							state <= WAIT_WBU;
						
							rready <= 0;
							unshftMemDataR <= rdata;
							memDataReady <= 1;
						end else begin
							$display("ERROR: LSU: rresp=%b, rid=%b, arid=%b, rlast=%b", rresp, rid, arid, rlast);
							$finish;
						end
					end 
				end
				SEND_AWADDR_WDATA: begin
					if (awvalid && awready) begin
						state <= WAIT_WRESP;

						awvalid <= 0;
						wvalid <= 0;
					end
				end
				WAIT_WRESP: begin
					if (delay_trigger)	
						bready <= 1;
					if (bvalid && bready) begin
						if (bid==awid && bresp==2'b00 /*OKAY*/) begin
							state <= WAIT_WBU;

							bready <= 0;
							memDataReady <= 1;
						end else begin 
							$display("ERROR: LSU: bid=%b, awaddr=%x, bresp=%b", bid, awaddr, bresp);
							$finish;
						end

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

	// Shift valid bytes to the LSB of the data according to ByteSel
	wire [1:0] ByteSel;
	assign ByteSel = memAddr[1:0];

	// Memory bit extension
	ysyx_23060061_MuxKey #(5, 3, 32) memDataR_ext(
		.out(memDataR),
		.key(memExt),
		.lut({
			3'b000, unextMemDataR,
			3'b001, {{24{unextMemDataR[7]}}, unextMemDataR[7:0]}, 
			3'b010, {{16{unextMemDataR[15]}}, unextMemDataR[15:0]}, 
			3'b011, {24'd0, unextMemDataR[7:0]},
			3'b100, {16'd0, unextMemDataR[15:0]}
		})
  	);
	
	ysyx_23060061_MuxKey #(4, 2, 32) memDataR_shift(
		.out(unextMemDataR),
		.key(ByteSel),
		.lut({
			2'b00, unshftMemDataR,
			2'b01, {8'b00000000, unshftMemDataR[31:8]},
			2'b10, {16'b00000000, unshftMemDataR[31:16]},
			2'b11, {24'b00000000, unshftMemDataR[31:24]}
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