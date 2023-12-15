module ysyx_23060061_LSU(
	input [2:0] memExt,
	input [1:0] MemRW,
	input [31:0] memAddr,
	input [31:0] memDataW,
	input [3:0] wmask,
	input exu_valid,
	output lsu_ready,
	
	output lsu_valid,
	input wbu_ready,
	output [31:0] memDataR
);
	assign lsu_valid = exu_valid;
	assign lsu_ready = wbu_ready;
	wire [31:0] unextMemDataR;
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

  always @(MemRW, memAddr, memDataW) begin
	if (exu_valid) begin
    	if(MemRW==2'b10) begin
    		paddr_read(memAddr, unextMemDataR);
    	end else if (MemRW==2'b01) begin
    		paddr_write(memAddr, memDataW, {4'b0000, wmask});
    	end
	end
  end

endmodule