module ysyx_23060061_ALU #(WIDTH = 1, RESET_VAL = 0) (
  input clk,
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  input [3:0] aluOp,
  output [WIDTH-1:0] aluOut
);

  wire [4:0] shamt;
  assign shamt = b[4:0];

  ysyx_23060061_MuxKey #(12, 4, WIDTH) alu_mux(
	.out(aluOut),
	.key(aluOp),
	.lut({
	  4'b0000, a+b, // addition
	  4'b0001, b,   // output_B
	  4'b0010, (a+b)&~1, // add and clear lowest bit
	  4'b0011, a-b, // subtraction
	  4'b0100, a<b ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}},     // sltu
	  4'b0101, $signed(a)<$signed(b) ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}},     // slt
	  4'b0110, a^b, // xor
	  4'b0111, $signed(a) >>> shamt, // srai 
	  4'b1000, a|b, // or
	  4'b1001, a&b,  // and
	  4'b1010, a<<shamt, // sll
	  4'b1011, a>>shamt// srl
	})
  );
endmodule
