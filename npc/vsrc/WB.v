// module ysyx_23060061_WB(
// 	input clk,
// 	input rst,
//
// 	input mfu_valid,
// 	input [1:0] WBSel,
// 	input [31:0] memDataR,
// 	input [31:0] aluOut,
// 	input [31:0] snpc,
// 	input [31:0] csrReadData,
// 	input [31:0] dnpc_in,
// 	output [31:0] dnpc_out,
// 	output [31:0] regDataWB
// );
//   ysyx_23060061_MuxKey #(4, 2, 32) wb_mux(
// 	.out(regDataWB),
// 	.key(WBSel),
// 	.lut({
// 		2'b00, memDataR,
// 		2'b01, aluOut,
// 		2'b10, snpc,
//     	2'b11, csrReadData
// 	})
//   );
//   assign dnpc_out = mfu_valid ? dnpc_in 
// endmodule