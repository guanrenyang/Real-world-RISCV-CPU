// import "DPI-C" function void paddr_read(input int raddr, output int rdata);
module ysyx_23060061_IFU_with_SRAM(
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

	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output reg rready,

	output [31:0] awaddr,
	output reg awvalid,
	input awready,

	output [31:0] wdata,
	output [3:0] wstrb,
	output reg wvalid,
	input wready,

	input bresp,
	input bvalid,
	output bready
);	

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
	
	reg [1:0] state;

	// Sequential logic
	always @(posedge clk) begin
		if (~rst) begin // do reset
			// signals for InstMem
			arvalid <= 0;	
			awvalid <= 0;
			wvalid <=0;
			// signals for IDU				
			inst <= 0;
			pc_old <= 0;
			instValid <= 0;
		end else begin
			case (state)
				IDLE: begin
					if(pc_old != pc) begin// need to read InstMem
						state <= SEND_ADDR; // state transition
						
						araddr <= pc;
						arvalid <= 1;
						rready <= 0;
					end
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
						state <= IDLE;
						rready <= 0;
						inst <= rdata;
						instValid <= 1;
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