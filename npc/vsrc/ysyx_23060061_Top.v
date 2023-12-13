import "DPI-C" function void trap();
import "DPI-C" function void paddr_read(input int raddr, output int rdata);
import "DPI-C" function void paddr_write(input int waddr, input int wdata, input byte wmask);

module ysyx_23060061_Top (
  input clk,
  input rst, 
  // input [31 : 0] inst,
  // output [31 : 0] pc,
  output [31 : 0] ftrace_dnpc // used only for ftrace
);
  // IF: reg PC and its updating rule.
  wire [31:0] inst;
  wire [31:0] pc;
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
  
  wire [31:0] regDataWB;

  /* For Branch */
  wire BrUn;
  wire BrEq;
  wire BrLt;

  /* For CSR */
  wire csrEn;
  wire [31:0] csr_rdata;
 
  wire ebreak;
  wire ecall;
  wire mret;
 
  wire [31:0] mtvec;
  wire [31:0] mepc;

  assign snpc = pc + 4;
  assign dnpc = mret == 1 ? mepc : (ecall == 1 ? mtvec : (PCSel == 0 ? snpc : aluOut));
  ysyx_23060061_Reg #(32, 32'h80000000) pc_reg(.clk(clk), .rst(rst), .din(dnpc), .dout(pc), .wen(1'b1));

  assign ftrace_dnpc = dnpc; // for ftrace
  always @(pc) begin
	if (!rst) begin
		paddr_read(pc, inst);
	end
  end

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
  
  /* Register File */
  // GPRs 
  ysyx_23060061_GPRs #(5, 32) GPRs(
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
  // CSRs
  ysyx_23060061_CSRs #(32) CSRs(
    .clk(clk),
    .rst(rst),
    .csrEn(csrEn),
    .csrId(inst[31:20]),
    .wdata(aluOut),
    .rdata(csr_rdata),
    .ecall(ecall),
    .pc(pc),
    .mtvec(mtvec),
    .mepc(mepc)
  );
  
  ysyx_23060061_ImmGen imm_gen(.inst(inst[31:7]), .ImmSel(instType), .imm(imm));

  // EX
  assign aluOpA = aluAsel == 0 ? regData1 : pc;
  ysyx_23060061_MuxKey #(3, 2, 32) aluOpBselect(
	.out(aluOpB),
	.key(aluBsel),
	.lut({
		2'b00, regData2,
		2'b01, imm,
		2'b10, csr_rdata
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
	// if(!clk) begin
    	if(MemRW==2'b10) begin
    		paddr_read(memAddr, unextMemDataR);
    	end else if (MemRW==2'b01) begin
    		paddr_write(memAddr, memDataW, {4'b0000, wmask});
    	end
	// end
  end


  // WB
  ysyx_23060061_MuxKey #(4, 2, 32) wb_mux(
	.out(regDataWB),
	.key(WBSel),
	.lut({
		2'b00, memDataR,
		2'b01, aluOut,
		2'b10, snpc,
    	2'b11, csr_rdata
	})
  );
  
  
endmodule

