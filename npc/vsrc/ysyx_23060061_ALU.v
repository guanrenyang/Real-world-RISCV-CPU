module ysyx_23060061_ALU #(WIDTH = 1, RESET_VAL = 0) (
  input clk,
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  input [3:0] aluOp,
  output [WIDTH-1:0] aluOut
);

  ysyx_23060061_MuxKey #(5, 4, WIDTH) alu_mux(
	.out(aluOut),
	.key(aluOp),
	.lut({
	  4'b0000, a+b, // addition
	  4'b0001, b,   // output_B
	  4'b0010, (a+b)&~1, // add and clear lowest bit
	  4'b0011, a-b, // subtraction
	  4'b0100, a<b ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}}     // sltu
	})
  );
endmodule
