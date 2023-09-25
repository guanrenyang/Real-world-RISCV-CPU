define ysys_23060061_Width 32

module ysyx_23060061_Top (
  input clk,
  input rst, 
  input [ysys_23060061_Width-1 : 0] inst,
  output [ysys_23060061_Width-1 : 0] pc
);
  // IF: reg PC and its updating rule.
  wire pc;
  ysyx_23060061_Reg #(32, 32'h80000000) pc_reg(.clk(clk), .rst(rst), .din(snpc), .dout(pc), .wen(1'b1));
  assign snpc = pc + 4;
  
  // ID: Decoder unit
  wire RegWrite;
  ysyx_23060061_Decoder(.opcode(inst[6:0]), .funct3(inst[14:12]), .RegWrite(RegWrite));
  
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd = inst[11:7];
  
  wire regData1;
  wire regData2;
  // Register File
  ysys_23060061_RegisterFile #(5, 32) registerFile(
    .clk(clk),
    .wdata(aluOut),
    .waddr(rd),
    .wen(RegWrite),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(regData1),
    .rdata2(regData2)
  );

  // EX
  wire [ysys_23060061_Width-1:0] imm;
  assign imm = {20{inst[31]}, inst[31:20]}; // Sign extension

  wire aluOut;
  ysys_23060061_ALU(.clk(clk), .a(regData1), .b(imm), .aluOut(aluOut));

endmodule

