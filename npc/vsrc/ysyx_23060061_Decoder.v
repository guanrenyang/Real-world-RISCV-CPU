`include "global.vh"

module ysyx_23060061_Decoder (
  input [6:0] opcode,
  input [2:0] funct3,

  output [2:0] instType,

  output RegWrite,
  output ebreak,
  output PCSel,
  output aluAsel,
  output aluBsel,
  output MemWrite,
  output [1:0] WBSel,
  output [1:0] aluOp // 00: add, 01:output_B, 10: add and clear lowest bit
);
  ysyx_23060061_MuxKeyWithDefault #(7, 10, 10) decoder(
	.out({RegWrite, ebreak, PCSel, aluAsel, aluBsel, MemWrite, WBSel, aluOp}), 
	.key({opcode, (opcode != 7'b0010111 && opcode != 7'b0110111 && opcode != 7'b1101111)? funct3 : 3'b000}), 
	.default_out({10'b0000000000}), 
	.lut({
    	{7'b0010011, 3'b000}, {10'b1100100100}, // addi
    	{7'b1110011, 3'b000}, {10'bx1xxxxxxxx}, // ebreak

		{7'b0010111, 3'b000}, {10'b1001100100}, // auipc
		{7'b0110111, 3'b000}, {10'b100x100101}, // lui
		{7'b1101111, 3'b000}, {10'b1011101000}, // jal
		{7'b1101111, 3'b000}, {10'b1011101010}, // jalr
		{7'b0100011, 3'b010}, {10'b000011xx00}  // sw
	}));
  
  ysyx_23060061_MuxKey #(9, 7, 3) decoder_instType(.out(instType), .key(opcode), .lut({
	{7'b0110111}, `ysyx_23060061_TYPE_U,
	{7'b0010111}, `ysyx_23060061_TYPE_U,
	{7'b1101111}, `ysyx_23060061_TYPE_J,
	{7'b1100111}, `ysyx_23060061_TYPE_I,
	{7'b0000011}, `ysyx_23060061_TYPE_I,
	{7'b0010011}, `ysyx_23060061_TYPE_I,
	{7'b1100011}, `ysyx_23060061_TYPE_B,
	{7'b0100011}, `ysyx_23060061_TYPE_S,
	{7'b0110011}, `ysyx_23060061_TYPE_R
  }));
endmodule
