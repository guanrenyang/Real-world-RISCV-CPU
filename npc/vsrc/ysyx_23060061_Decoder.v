`include "global.vh"

module ysyx_23060061_Decoder (
  input [6:0] opcode,
  input [2:0] funct3,
  input [6:0] funct7,
  
  input BrEq,
  input BrLt,

  output [2:0] instType,

  output RegWrite,
  output [1:0] MemRW, // 00 idle, 10 read, 01 write
  output ebreak,
  output PCSel,
  output aluAsel,
  output aluBsel,
  output [1:0] WBSel,
  output [3:0] aluOp, // 0000: add, 0001:output_B, 0010: add and clear lowest bit, 0011: sub, 0100: sltu, 0101: slt, 0110: xor
  output BrUn // branch unsigned
);
 //  ysyx_23060061_MuxKeyWithDefault #(8, 10, 11) decoder(
	// .out({RegWrite, MemRW, ebreak, PCSel, aluAsel, aluBsel, WBSel, aluOp}), 
	// .key({opcode, (opcode != 7'b0010111 && opcode != 7'b0110111 && opcode != 7'b1101111)? funct3 : 3'b000}), 
	// .default_out({11'b00000000000}), 
	// .lut({
 //    	{7'b0010011, 3'b000}, {11'b10000010100}, // addi
 //    	{7'b1110011, 3'b000}, {11'bxxx1xxxxxxx}, // ebreak
	//
	                                                     // 	{7'b0010111, 3'b000}, {11'b10000110100}, // auipc
	                                                     // 	{7'b0110111, 3'b000}, {11'b10000x10101}, // lui
	                                                     // 	{7'b1101111, 3'b000}, {11'b10001111000}, // jal
	// 	{7'b1100111, 3'b000}, {11'b10001011010}, // jalr
	// 	{7'b0100011, 3'b010}, {1'b0, 2'b01, 1'b0, 1'b0, 1'b0, 1'b1, 2'bxx, 2'b00}, // sw
	// 	{7'b0000011, 3'b010}, {1'b1, 2'b10, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, 2'b00} // lw
	// }));

  // output signals determined directly by the opcode
  wire RegWrite_0;
  wire [1:0] MemRW_0;
  wire ebreak_0;
  wire PCSel_0;
  wire aluAsel_0;
  wire aluBsel_0;
  wire [1:0] WBSel_0;
  wire [3:0] aluOp_0;

  // output signals determined by the opcode and funct3
  wire RegWrite_1;
  wire [1:0] MemRW_1;
  wire ebreak_1;
  wire PCSel_1;
  wire aluAsel_1;
  wire aluBsel_1;
  wire [1:0] WBSel_1;
  wire [3:0] aluOp_1;

  // output signals determined by the opcode, funct3 and funct7
  wire RegWrite_2;
  wire [1:0] MemRW_2;
  wire ebreak_2;
  wire PCSel_2;
  wire aluAsel_2;
  wire aluBsel_2;
  wire [1:0] WBSel_2;
  wire [3:0] aluOp_2;

  ysyx_23060061_MuxKeyWithDefault #(3, 7, 13) decoder_from_opcode(
	.out({RegWrite_0, MemRW_0, ebreak_0, PCSel_0, aluAsel_0, aluBsel_0, WBSel_0, aluOp_0}),
	.key(opcode),
	.default_out({13'b00000000000}),
	.lut({
		{7'b0010111}, {13'b1000011010000}, // auipc
		{7'b0110111}, {13'b10000x1010001}, // lui
		{7'b1101111}, {13'b1000111100000} // jal
	})
  );
  
  ysyx_23060061_MuxKeyWithDefault #(12, 10, 14) decoder_from_opcode_funct3(
	.out({RegWrite_1, MemRW_1, ebreak_1, PCSel_1, aluAsel_1, aluBsel_1, WBSel_1, aluOp_1, BrUn}),
	.key({opcode, funct3}),
	.default_out({/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 1'b0, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0}),
	.lut({
    	{7'b0010011, 3'b000}, {14'b10000010100000}, // addi
    	{7'b1110011, 3'b000}, {14'bxxx1xxxxxxxxx0}, // ebreak
		{7'b1100111, 3'b000}, {14'b10001011000100}, // jalr
		{7'b0100011, 3'b010}, {1'b0, 2'b01, 1'b0, 1'b0, 1'b0, 1'b1, 2'bxx, 4'b0000, 1'b0}, // sw
		{7'b0000011, 3'b010}, {1'b1, 2'b10, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, 4'b0000, 1'b0}, // lw
		{7'b0010011, 3'b011}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 1'b1, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0100, /*BrUn*/ 1'b0}, // sltiu
			
		{7'b1100011, 3'b000}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 1'b1, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0}, // beq
		{7'b1100011, 3'b001}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 1'b1, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0}, // bne
		{7'b1100011, 3'b100}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 1'b1, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0}, // blt
		{7'b1100011, 3'b101}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 1'b1, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0}, // bge
		{7'b1100011, 3'b110}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 1'b1, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b1}, // bltu
		{7'b1100011, 3'b111}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 1'b1, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b1} // bgeu
	})
  );

  ysyx_23060061_MuxKeyWithDefault #(4, 17, 13) decoder_from_opcode_funct3_funct7(
	.out({RegWrite_2, MemRW_2, ebreak_2, PCSel_2, aluAsel_2, aluBsel_2, WBSel_2, aluOp_2}),
	.key({opcode, funct3, funct7}),
	.default_out({13'b00000000000}),
	.lut({
		{7'b0110011, 3'b000, 7'b0000000}, {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 2'b01, 4'b0000}, // add
		{7'b0110011, 3'b000, 7'b0100000}, {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 2'b01, 4'b0011}, // sub
		{7'b0110011, 3'b100, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 1'b0, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0110}, // xor

		{7'b0110011, 3'b011, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 1'b0, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0100} //sltu
	})
  );

  wire PC_branch;
  ysyx_23060061_MuxKeyWithDefault #(6, 10, 1) branch_decoder(
	.out(PC_branch),
	.key({opcode, funct3}),
	.default_out(1'b0),
	.lut({
		{7'b1100011, 3'b000}, BrEq, // beq
		{7'b1100011, 3'b001}, !BrEq, // bne
		{7'b1100011, 3'b100}, BrLt, // blt
		{7'b1100011, 3'b101}, !BrLt, // bge
		{7'b1100011, 3'b110}, BrLt, // bltu
		{7'b1100011, 3'b111}, !BrLt  // bgeu
	})
  );

  // pick the final signal
  assign RegWrite = RegWrite_0 | RegWrite_1 | RegWrite_2;
  assign MemRW = MemRW_0 | MemRW_1 | MemRW_2;
  assign ebreak = ebreak_0 | ebreak_1 | ebreak_2;
  assign aluAsel = aluAsel_0 | aluAsel_1 | aluAsel_2;
  assign aluBsel = aluBsel_0 | aluBsel_1 | aluBsel_2;
  assign WBSel = WBSel_0 | WBSel_1 | WBSel_2;
  assign aluOp = aluOp_0 | aluOp_1 | aluOp_2;
  assign PCSel = PCSel_0 | PCSel_1 | PCSel_2 | PC_branch;

		// {7'b0110011, 3'b000}, {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 2'b01, 2'b00}, // add
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
