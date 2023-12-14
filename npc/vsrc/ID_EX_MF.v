module ID_EX_WB (
  input clk,
  input rst, 

  // signals from IFU
  input ifu_valid,
  input [31:0] inst,
  input [31:0] pc,
  //signals for GRP
  output [4:0] rd,
  output [4:0] rs1,
  output [4:0] rs2,
  output RegWrite,
  output [31:0] regDataWB,
  input [31:0] regData1,
  input [31:0] regData2,
  // For CSRs
  output csrEn,
  output [11:0] csrId,
  output [31:0] csrWriteData,
  output ecall,
  input [31:0] csrReadData,
  input [31:0] mtvec,
  input [31:0] mepc,
  
  // signals to WB
  output [31:0] dnpc,
  // signals out from top
  output [31:0] ftrace_dnpc // used only for ftrace
);
  // IF: reg PC and its updating rule.
  wire [31:0] snpc;
  // wire [31:0] dnpc;
  wire [31:0] imm;

  wire [1:0] MemRW;
  wire [31:0] memDataW;
  wire [31:0] unextMemDataR;
  wire [31:0] memDataR;
  wire [31:0] memAddr;
  wire [3:0] wmask;
  wire [2:0] memExt;
  
  wire [2:0] instType;

  wire [31:0] aluOpA;
  wire [31:0] aluOpB;
  wire [31:0] aluOut;

  wire [3:0] aluOp;
  wire [1:0] WBSel;
  wire PCSel;
  wire aluAsel;
  wire [1:0] aluBsel;
  

  /* For Branch */
  wire BrUn;
  wire BrEq;
  wire BrLt;

  wire ebreak;
  // wire ecall;
  wire mret;
 
  assign snpc = pc + 4;
  assign dnpc = ifu_valid == 0 ? pc : (mret == 1 ? mepc : (ecall == 1 ? mtvec : (PCSel == 0 ? snpc : aluOut)));

  assign ftrace_dnpc = dnpc; // for ftrace

  // ID: Decoder unit
  ysyx_23060061_Decoder decoder(
  	.inst(inst),
	.BrEq(BrEq),
	.BrLt(BrLt),

	.wmask(wmask),
	.memExt(memExt),

	.ebreak(ebreak),
  	.ecall(ecall),
  	.mret(mret),
  
	.instType(instType),
	.RegWrite(RegWrite), 
	.MemRW(MemRW),
  	.csrEn(csrEn),
	.PCSel(PCSel),
	.aluAsel(aluAsel),
	.aluBsel(aluBsel),
	.WBSel(WBSel),
	.aluOp(aluOp),
	.BrUn(BrUn)
  );

  always @(*) begin
    if(ebreak) trap(); 
  end

  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd = inst[11:7];
  
  // CSRs
  assign csrId = inst[31:20];
  assign csrWriteData = aluOut;

  ysyx_23060061_ImmGen imm_gen(.inst(inst[31:7]), .ImmSel(instType), .imm(imm));

  // EX
  assign aluOpA = aluAsel == 0 ? regData1 : pc;
  ysyx_23060061_MuxKey #(3, 2, 32) aluOpBselect(
	.out(aluOpB),
	.key(aluBsel),
	.lut({
		2'b00, regData2,
		2'b01, imm,
		2'b10, csrReadData
	})
  );
  ysyx_23060061_ALU #(32, 32'd0) alu(.clk(clk), .a(aluOpA), .b(aluOpB), .aluOut(aluOut), .aluOp(aluOp));
  
  // Branch
  ysyx_23060061_BranchComp branchComp(
	.rdata1(regData1), 
	.rdata2(regData2), 
	.BrUn(BrUn), 
	.BrEq(BrEq), 
	.BrLt(BrLt)
  );

  // MEM
  assign memDataW = regData2;
  assign memAddr = aluOut; 
  ysyx_23060061_MuxKey #(5, 3, 32) memDataR_ext(
	.out(memDataR),
	.key(memExt),
	.lut({
		3'b000, unextMemDataR,
		3'b001, {{24{unextMemDataR[7]}}, unextMemDataR[7:0]},
		3'b010, {{16{unextMemDataR[15]}}, unextMemDataR[15:0]},
		3'b011, {24'd0, unextMemDataR[7:0]},
		3'b100, {16'd0, unextMemDataR[15:0]}
	})
  );

  always @(MemRW, memAddr, memDataW) begin
	if (ifu_valid) begin
    	if(MemRW==2'b10) begin
    		paddr_read(memAddr, unextMemDataR);
    	end else if (MemRW==2'b01) begin
    		paddr_write(memAddr, memDataW, {4'b0000, wmask});
    	end
	end
  end


  // WB
  ysyx_23060061_MuxKey #(4, 2, 32) wb_mux(
	.out(regDataWB),
	.key(WBSel),
	.lut({
		2'b00, memDataR,
		2'b01, aluOut,
		2'b10, snpc,
    	2'b11, csrReadData
	})
  );
  
  
endmodule

