define ysys_23060061_Width 32

module ysyx_23060061_Top (
  input clk,
  input rst, 
  input [ysys_23060061_Width-1 : 0] inst,
  output [ysys_23060061_Width-1 : 0] snpc
);
  // IF: reg PC and its updating rule.
  wire pc;
  ysyx_23060061_Reg #(32, 32'h80000000) pc_reg(.clk(clk), .rst(rst), snpc, pc);
  assign snpc = pc + 4;
  
  // ID: Decoder unit
   
endmodule

