`include "global.vh"

module ysyx_23060061_ImmGen(
	input [31:7] inst,
	input [2:0] ImmSel,
	output [31:0] imm
);
// This is module of riscv32I instruction set for generating immediate numbers. 
// It takes 32-bit instruction as input and generates 32-bit immediate number as output.
// The immediate number is generated according to the ImmSel.

	// parameter [2:0] I = 3'b000, S = 3'b001, B = 3'b010, U = 3'b011, J = 3'b100;
	
	ysyx_23060061_MuxKey #(5, 3, 32) imm_gen (
		.out(imm),
		.key(ImmSel),
		.lut({
			`ysyx_23060061_TYPE_I, {{20{inst[31]}}, inst[31:20]},
			`ysyx_23060061_TYPE_S, {{20{inst[31]}}, inst[31:25], inst[11:7]},
			`ysyx_23060061_TYPE_B, {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0},
			`ysyx_23060061_TYPE_U, {inst[31:12], 12'b0},
			`ysyx_23060061_TYPE_J, {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}
		})
	);
endmodule
