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
	output reg [31:0] memDataR
);
	wire [31:0] unextMemDataR;

    wire [31:0] memDataR_internal;
	reg DataMemValid_internal;

	ysyx_23060061_MuxKey #(5, 3, 32) memDataR_ext(
		.out(memDataR_internal),
		.key(memExt),
		.lut({
			3'b000, unextMemDataR,
			3'b001, {{24{unextMemDataR[7]}}, unextMemDataR[7:0]}, 3'b010, {{16{unextMemDataR[15]}}, unextMemDataR[15:0]}, 3'b011, {24'd0, unextMemDataR[7:0]},
			3'b100, {16'd0, unextMemDataR[15:0]}
		})
  	);

  always @(MemRW, memAddr, memDataW) begin
	if (exu_valid) begin
    	if(MemRW==2'b10) begin
    		paddr_read(memAddr, unextMemDataR);
    	end else if (MemRW==2'b01) begin
    		paddr_write(memAddr, memDataW, {4'b0000, wmask});
    	end
	end
  end
  
  always @(posedge clk) begin
	if (rst) begin
		memDataR <= 0;
		DataMemValid_internal <= 0;
	end else begin
		memDataR <= memDataR_internal;
		DataMemValid_internal <= exu_valid & ~wbu_ready;
	end
  end
  assign lsu_valid = (DataMemValid_internal); 
  assign lsu_ready = wbu_ready;
endmodule