import "DPI-C" function void trap();
import "DPI-C" function void pmem_read(input int raddr, output int rdata);
import "DPI-C" function void pmem_write(input int waddr, output int wdata, input byte wmask);

module ysyx_23060061_Top (
  input clk,
  input rst, 
  input [31 : 0] inst,
  output [31 : 0] pc,
  output [31 : 0] ftrace_dnpc // used only for ftrace
);
  // IF: reg PC and its updating rule.
  wire [31:0] snpc;
  wire [31:0] dnpc;
  wire [31:0] imm;
  wire RegWrite;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [4:0] rs1;
  wire [31:0] regData1;
  wire [31:0] regData2;
  
  wire [1:0] MemRW;
  wire [31:0] memDataW;
  wire [31:0] memDataR;
  wire [31:0] memAddr;

  wire ebreak;
  wire [2:0] instType;

  wire [31:0] aluOpA;
  wire [31:0] aluOpB;
  wire [31:0] aluOut;

  wire [1:0] aluOp;
  wire [1:0] WBSel;
  wire PCSel;
  wire aluAsel;
  wire aluBsel;
  
  wire [31:0] regDataWB;

  assign snpc = pc + 4;
  assign dnpc = PCSel == 0 ? snpc : aluOut;
  ysyx_23060061_Reg #(32, 32'h80000000) pc_reg(.clk(clk), .rst(rst), .din(dnpc), .dout(pc), .wen(1'b1));
  assign ftrace_dnpc = dnpc;

  // ID: Decoder unit
  ysyx_23060061_Decoder decoder(
	.opcode(inst[6:0]), 
	.funct3(inst[14:12]), 

	.instType(instType),
	.RegWrite(RegWrite), 
	.MemRW(MemRW),
	.ebreak(ebreak),
	.PCSel(PCSel),
	.aluAsel(aluAsel),
	.aluBsel(aluBsel),
	.WBSel(WBSel),
	.aluOp(aluOp)
  );

  always @(*) begin
    if(ebreak) trap(); 
  end

  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd = inst[11:7];
  
  // Register File
  ysyx_23060061_RegisterFile #(5, 32) registerFile(
    .clk(clk),
    .rst(rst),
    .wdata(regDataWB),
    .waddr(rd),
    .wen(RegWrite),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(regData1),
    .rdata2(regData2)
  );
  
  ysyx_23060061_ImmGen imm_gen(.inst(inst[31:7]), .ImmSel(instType), .imm(imm));

  // EX
  assign aluOpA = aluAsel == 0 ? regData1 : pc;
  assign aluOpB = aluBsel == 0 ? regData2 : imm;
  ysyx_23060061_ALU #(32, 32'd0) alu(.clk(clk), .a(aluOpA), .b(aluOpB), .aluOut(aluOut), .aluOp(aluOp));
  
  // MEM
  assign memDataW = regData2;
  assign memAddr = aluOut; 
  always @(posedge clk) begin
	if(MemRW==2'b10) begin
		pmem_read(memAddr, memDataR);
	end else if (MemRW==2'b01) begin
		pmem_write(memAddr, memDataW, 8'b00001111);
	end
  end

  // WB
  ysyx_23060061_MuxKey #(3, 2, 32) wb_mux(
	.out(regDataWB),
	.key(WBSel),
	.lut({
		2'b00, memDataR,
		2'b01, aluOut,
		2'b10, snpc
	})
  );
endmodule

