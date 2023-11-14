`include "global.vh"

module ysyx_23060061_Decoder (
  input [6:0] opcode,
  input [2:0] funct3,

  output [2:0] instType,

  output RegWrite,
  output [1:0] MemRW, // 00 idle, 10 read, 01 write
  output ebreak,
  output PCSel,
  output aluAsel,
  output aluBsel,
  output [1:0] WBSel,
  output [1:0] aluOp // 00: add, 01:output_B, 10: add and clear lowest bit
);
  ysyx_23060061_MuxKeyWithDefault #(8, 10, 11) decoder(
	.out({RegWrite, MemRW, ebreak, PCSel, aluAsel, aluBsel, WBSel, aluOp}), 
	.key({opcode, (opcode != 7'b0010111 && opcode != 7'b0110111 && opcode != 7'b1101111)? funct3 : 3'b000}), 
	.default_out({11'b00000000000}), 
	.lut({
    	{7'b0010011, 3'b000}, {11'b10000010100}, // addi
    	{7'b1110011, 3'b000}, {11'bxxx1xxxxxxx}, // ebreak

		{7'b0010111, 3'b000}, {11'b10000110100}, // auipc
		{7'b0110111, 3'b000}, {11'b10000x10101}, // lui
		{7'b1101111, 3'b000}, {11'b10001111000}, // jal
		{7'b1100111, 3'b000}, {11'b10001011010}, // jalr
		{7'b0100011, 3'b010}, {1'b0, 2'b01, 1'b0, 1'b0, 1'b0, 1'b1, 2'bxx, 2'b00}, // sw
		{7'b0000011, 3'b010}, {1'b1, 2'b10, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, 2'b00} // lw
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
