`include "global.vh"

module ysyx_23060061_Decoder (
  input [6:0] opcode,
  input [2:0] funct3,
  input [6:0] funct7,
  
  input BrEq,
  input BrLt,

  output [2:0] memExt, // 000 no ext, 001 sign ext byte, 010 sign ext half word, 011 unsigned ext byte , 100 unsigned ext half word
  output [3:0] wmask,
  output [2:0] instType,

  output RegWrite,
  output [1:0] MemRW, // 00 idle, 10 read, 01 write
  output ebreak,
  output csrEn,
  output PCSel,
  output aluAsel,
  output [1:0] aluBsel,
  output [1:0] WBSel,
  output [3:0] aluOp, // 0000: add, 0001:output_B, 0010: add and clear lowest bit, 0011: sub, 0100: sltu, 0101: slt, 0110: xor, 0111: srai, 1000: or, 1001: and, 1010: sll, 1011: srl, 1100: output_A
  output BrUn // branch unsigned
);

  // output signals determined directly by the opcode
  wire RegWrite_0;
  wire [1:0] MemRW_0;
  wire ebreak_0;
  wire PCSel_0;
  wire aluAsel_0;
  wire [1:0] aluBsel_0;
  wire [1:0] WBSel_0;
  wire [3:0] aluOp_0;

  // output signals determined by the opcode and funct3
  wire RegWrite_1;
  wire [1:0] MemRW_1;
  wire ebreak_1;
  wire PCSel_1;
  wire aluAsel_1;
  wire [1:0] aluBsel_1;
  wire [1:0] WBSel_1;
  wire [3:0] aluOp_1;

  // output signals determined by the opcode, funct3 and funct7
  wire RegWrite_2;
  wire [1:0] MemRW_2;
  wire ebreak_2;
  wire PCSel_2;
  wire aluAsel_2;
  wire [1:0] aluBsel_2;
  wire [1:0] WBSel_2;
  wire [3:0] aluOp_2;

  ysyx_23060061_MuxKeyWithDefault #(3, 7, 14) decoder_from_opcode(
	.out({RegWrite_0, MemRW_0, ebreak_0, PCSel_0, aluAsel_0, aluBsel_0, WBSel_0, aluOp_0}),
	.key(opcode),
	.default_out({14'b000000000000}),
	.lut({
		{7'b0010111}, {14'b10000101010000}, // auipc
		{7'b0110111}, {14'b10000x01010001}, // lui
		{7'b1101111}, {14'b10001101100000} // jal
	})
  );
  
  ysyx_23060061_MuxKeyWithDefault #(24, 10, 23) decoder_from_opcode_funct3(
	.out({RegWrite_1, MemRW_1, ebreak_1, csrEn, PCSel_1, aluAsel_1, aluBsel_1, WBSel_1, aluOp_1, BrUn, memExt, wmask}),
	.key({opcode, funct3}),
	.default_out({/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b0, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}),
	.lut({
		{7'b1110011, 3'b000}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b1, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // ebreak 
        {7'b1100111, 3'b000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b1, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b10, /*aluOp*/ 4'b0010, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // jalr
		/* Calculate */
		{7'b0010011, 3'b000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // addi
		{7'b0010011, 3'b100}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0110, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // xori
		{7'b0010011, 3'b110}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b1000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // ori
		{7'b0010011, 3'b111}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b1001, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // andi
		/* Store */
		{7'b0100011, 3'b000}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b01, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0001}, // sb
		{7'b0100011, 3'b001}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b01, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0011}, // sh
		{7'b0100011, 3'b010}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b01, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b1111}, // sw
		/* Load */
		{7'b0000011, 3'b010}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b10, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // lw
		{7'b0000011, 3'b000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b10, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b001, /*wmask*/ 4'b0000}, // lb
		{7'b0000011, 3'b100}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b10, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b011, /*wmask*/ 4'b0000}, // lbu
		{7'b0000011, 3'b001}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b10, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b010, /*wmask*/ 4'b0000}, // lh
		{7'b0000011, 3'b101}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b10, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b100, /*wmask*/ 4'b0000}, // lhu
		/* Conditional Set */
		{7'b0010011, 3'b010}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0101, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // slti
		{7'b0010011, 3'b011}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0100, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // sltiu
		/* Branch */
		{7'b1100011, 3'b000}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // beq
		{7'b1100011, 3'b001}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // bne
		{7'b1100011, 3'b100}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // blt
		{7'b1100011, 3'b101}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // bge
		{7'b1100011, 3'b110}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b1, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // bltu
		{7'b1100011, 3'b111}, {/*RegWrite*/ 1'b0,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b1, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b00, /*aluOp*/ 4'b0000, /*BrUn*/ 1'b1, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // bgeu
		/* CSR Instructioins */
		{7'b1110011, 3'b001}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b1, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b10, /*WBSel*/ 2'b11, /*aluOp*/ 4'b1100, /*BrUn*/ 1'b1, /*memExt*/ 3'b000, /*wmask*/ 4'b0000}, // csrrw
		{7'b1110011, 3'b010}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*csrEn*/ 1'b1, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b10, /*WBSel*/ 2'b11, /*aluOp*/ 4'b1000, /*BrUn*/ 1'b0, /*memExt*/ 3'b000, /*wmask*/ 4'b0000} // csrrs
	})
  );

  ysyx_23060061_MuxKeyWithDefault #(13, 17, 14) decoder_from_opcode_funct3_funct7(
	.out({RegWrite_2, MemRW_2, ebreak_2, PCSel_2, aluAsel_2, aluBsel_2, WBSel_2, aluOp_2}),
	.key({opcode, funct3, funct7}),
	.default_out({14'b00000000000}),
	.lut({
		{7'b0110011, 3'b000, 7'b0000000}, {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 2'b00, 2'b01, 4'b0000}, // add
		{7'b0110011, 3'b000, 7'b0100000}, {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 2'b00, 2'b01, 4'b0011}, // sub
		{7'b0110011, 3'b100, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0110}, // xor
		{7'b0110011, 3'b110, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b01, /*aluOp*/ 4'b1000}, // or
		{7'b0110011, 3'b111, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b01, /*aluOp*/ 4'b1001}, // and

		// shift I-type
		{7'b0010011, 3'b001, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b1010}, //slli
		{7'b0010011, 3'b101, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b1011}, //srli
		{7'b0010011, 3'b101, 7'b0100000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b01, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0111}, //srai
		// shift R-type
		{7'b0110011, 3'b001, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b01, /*aluOp*/ 4'b1010}, //sll
		{7'b0110011, 3'b101, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b01, /*aluOp*/ 4'b1011}, //srl
		{7'b0110011, 3'b101, 7'b0100000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0111}, //sra

		// slt
		{7'b0110011, 3'b010, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0101}, //slt
		{7'b0110011, 3'b011, 7'b0000000}, {/*RegWrite*/ 1'b1,  /*MemRW*/ 2'b00, /*ebreak*/ 1'b0, /*PCSel*/ 1'b0, /*aluAsel*/ 1'b0, /*aluBsel*/ 2'b00, /*WBSel*/ 2'b01, /*aluOp*/ 4'b0100} //sltu

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
  ysyx_23060061_MuxKey #(10, 7, 3) decoder_instType(.out(instType), .key(opcode), .lut({
	{7'b0110111}, `ysyx_23060061_TYPE_U,
	{7'b0010111}, `ysyx_23060061_TYPE_U,
	{7'b1101111}, `ysyx_23060061_TYPE_J,
	{7'b1100111}, `ysyx_23060061_TYPE_I,
	{7'b0000011}, `ysyx_23060061_TYPE_I,
	{7'b0010011}, `ysyx_23060061_TYPE_I,
	{7'b1110011}, `ysyx_23060061_TYPE_I, // CSR
	{7'b1100011}, `ysyx_23060061_TYPE_B,
	{7'b0100011}, `ysyx_23060061_TYPE_S,
	{7'b0110011}, `ysyx_23060061_TYPE_R
  }));

endmodule
