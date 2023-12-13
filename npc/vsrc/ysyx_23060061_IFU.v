// import "DPI-C" function void paddr_read(input int raddr, output int rdata);

module ysyx_23060061_IFU_with_SRAM(
	input clk,
	input rst,
	input [31:0] pc,
	output instValid,
	output [31:0] inst
);	
  wire [31:0] instImm_internal;
  always @(pc) begin 

  end
  ysyx_23060061_Reg #(32, 0) instReg_internal(
	.clk(clk),
	.rst(rst),
	.din(instImm_internal),
	.dout(inst),
	.wen(1'b1)
  );
  
  // always @(pc) begin
	 //  pc = pmem
  // end
endmodule