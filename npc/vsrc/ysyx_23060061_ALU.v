module ysyx_23060061_ALU #(WIDTH = 1, RESET_VAL = 0) (
  input clk,
  input rst,
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  output [WIDTH-1:0] aluOut
);
// Currently, the ALU only supports addition 

  ysyx_23060061_Reg #(WIDTH, RESET_VAL) aluOut_reg(clk, rst, ) 
endmodule
