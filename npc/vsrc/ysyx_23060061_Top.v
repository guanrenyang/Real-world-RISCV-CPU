// import "DPI-C" function void trap ();

module ysyx_23060061_Top (
  input clk,
  input rst, 
  input [31 : 0] inst,
  output [31 : 0] pc
);
  // IF: reg PC and its updating rule.
  wire [31:0] snpc;
  wire [31:0] imm;
  wire RegWrite;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [4:0] rs1;
  wire [31:0] regData1;
  wire [31:0] regData2;
  wire [31:0] aluOut;
  wire ebreak;

  assign snpc = pc + 4;
  ysyx_23060061_Reg #(32, 32'h80000000) pc_reg(.clk(clk), .rst(rst), .din(snpc), .dout(pc), .wen(1'b1));
  
  // ID: Decoder unit
  ysyx_23060061_Decoder decoder(.opcode(inst[6:0]), .funct3(inst[14:12]), .RegWrite(RegWrite), .ebreak(ebreak));
  
  // always @(posedge clk) begin
  //   if(ebreak) trap(); 
  // end

  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd = inst[11:7];
  
  // Register File
  ysyx_23060061_RegisterFile #(5, 32) registerFile(
    .clk(clk),
    .rst(rst),
    .wdata(aluOut),
    .waddr(rd),
    .wen(RegWrite),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(regData1),
    .rdata2(regData2)
  );

  // EX
  assign imm = {{20{inst[31]}}, inst[31:20]}; // Sign extension (only for I-type)

  ysyx_23060061_ALU #(32, 32'd0) alu(.clk(clk), .a(regData1), .b(imm), .aluOut(aluOut));

endmodule

