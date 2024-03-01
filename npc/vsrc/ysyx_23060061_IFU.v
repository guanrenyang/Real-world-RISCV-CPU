// import "DPI-C" function void paddr_read(input int raddr, output int rdata);
module ysyx_23060061_IFU(
	input clk,
	input rst,
	input [31:0] dnpc,
	input [31:0] pc,
	output reg [31:0] inst,
	output reg instValid,
	input iduReady,
	
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

	output [31:0] awaddr,
	output awvalid,
	output [3:0] awid, // AXI4
	output [7:0] awlen, // AXI4
	output [2:0] awsize, // AXI4
	output [1:0] awburst, // AXI4
	input awready,

	output [31:0] wdata,
	output [3:0] wstrb,
	output wvalid,
	output wlast, // AXI4
	input wready,

	input [1:0] bresp,
	input bvalid,
	input [3:0] bid, // AXI4
	output bready
);	

	// Write channel of IFU is not used
	assign awvalid = 0;
	assign awaddr = 0;
	assign awid = 0;
	assign awlen = 0;
	assign awsize = 0;
	assign awburst = 0;

	assign wdata = 0;
	assign wvalid = 0;
	assign wstrb = 0;
	assign wlast = 0;

	assign bready = 0;
	// End of write channel
		
	reg [31:0] instImm_internal;

	reg [31:0] pc_old;
	
	// // Combinationa logic
	// always @(pc!=pc_old) begin
	// 	if (!rst) begin
	// 		paddr_read(pc, instImm_internal);
	// 	end
	// end

	parameter IDLE = 0;
	parameter SEND_ADDR = 1;
	parameter WAIT_DATA = 2; 
	parameter WAIT_CPU = 3;	

	reg [1:0] state;

	// Random delay generator
	wire delay_trigger;
	ysyx_23060061_RandomDelayGenerator randomDelayGenerator(
		.clk(clk),
		.rst(rst),
		.delay_trigger(delay_trigger)
	);

	// Sequential logic
	always @(posedge clk) begin
		if (~rst) begin // do reset
			// signals for InstMem -- determined by AXI-Lite protocol
			arvalid <= 0;	
			// signals for IDU				
			inst <= 0;
			pc_old <= 0;
			instValid <= 0;
		end else begin
			case (state)
				IDLE: begin
					if(pc_old != pc) begin// need to read InstMem
						state <= SEND_ADDR; // state transition
						
						rready <= 0;
					end
					instValid <= 0;
				end
				SEND_ADDR: begin
					if (delay_trigger) begin
						araddr <= pc;
						arvalid <= 1;
						arid <= 4'b0000; // one read at a time so id won't change
						arlen <= 8'b00000000; // one read in a burst
						arsize <= 3'b010; // 32-bit read
						arburst <= 2'b01; // incrementing burst
					end

					if (arvalid && arready) begin
						state <= WAIT_DATA;
						arvalid <= 0;
					end
				end
				WAIT_DATA: begin
					if (delay_trigger) begin
						rready <= 1;		
					end
					if (rvalid & rready) begin
						/*
						* since ifu only reads 4 bytes at a time(arid==0, burst_len==1, arsize==4bytes, burst=type==fixex)
						* rlast is always 1 and rid always equals to arid
						*/
						if (rresp == 2'b00 /* OKAY */ && rid == arid && rlast) begin // finish read burst
							state <= WAIT_CPU;
							rready <= 0;
							inst <= rdata;
							instValid <= 1;
						end else begin
							$display("ERROR: IFU: rresp=%b, rid=%b, rlast=%b", rresp, rid, rlast);
							$finish;
						end
					end
				end
				WAIT_CPU: begin
					if (iduReady) begin
						state <= IDLE;
						instValid <= 0;
					end
				end
			endcase
			pc_old <= pc;

			// inst <= instImm_internal;
			// pc_old <= pc;
			// // instValid <= (pc_old == pc) ? 0 : 1;
			// instValid <= ~iduReady;
		end
	end	
endmodule