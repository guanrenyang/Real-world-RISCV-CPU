module ysyx_23060061_ALU #(WIDTH = 1, RESET_VAL = 0) (
  input clk,
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  input [1:0] aluOp,
  output [WIDTH-1:0] aluOut
);

  ysyx_23060061_MuxKey #(4, 2, WIDTH) alu_mux(
	.out(aluOut),
	.key(aluOp),
	.lut({
	  2'b00, a+b, // addition
	  2'b01, b,   // output_B
	  2'b10, (a+b)&~1, // add and clear lowest bit
	  2'b11, a-b // subtraction
	})
  );
endmodule
