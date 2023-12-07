/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "local-include/reg.h"
#include <cpu/cpu.h>
#include <cpu/ifetch.h>
#include <cpu/decode.h>



#define R(i) gpr(i)
#define CSR(i) csr(i)
#define Mr vaddr_read
#define Mw vaddr_write

enum {
  TYPE_I, TYPE_U, TYPE_S,
  TYPE_J, TYPE_R, TYPE_B,
  TYPE_N, // none
};

#define src1R() do { *src1 = R(rs1); } while (0)
#define src2R() do { *src2 = R(rs2); } while (0)
#define immI() do { *imm = SEXT(BITS(i, 31, 20), 12); } while(0)
#define immU() do { *imm = SEXT(BITS(i, 31, 12), 20) << 12; } while(0)
#define immS() do { *imm = (SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7); } while(0)
#define immJ() do { *imm = SEXT((BITS(i, 31, 31) << 20) | (BITS(i, 19, 12) << 12) | (BITS(i, 20, 20) << 11) | (BITS(i, 30, 21) << 1), 21) ; } while (0)
#define immB() do { *imm = SEXT((BITS(i, 31, 31) << 12) | (BITS(i, 30, 25) << 5) | (BITS(i, 11, 8) << 1) | (BITS(i, 7, 7) << 11), 13); } while (0) 

// size_t stack_top = -1; 
// vaddr_t func_addr_stack[10000];

char INDENT[1000] = "";
void ftrace(vaddr_t dnpc, vaddr_t pc, int rd, int rs1, int type){
  void source_func_name(vaddr_t addr, char* func_name);
  void source_func_addr(vaddr_t addr, vaddr_t* func_addr);
  bool is_func(vaddr_t addr);

  char curr_func_name[30];
  char func_name[30];
  vaddr_t func_addr;

  source_func_name(pc, curr_func_name);
  source_func_name(dnpc, func_name);
  source_func_addr(dnpc, &func_addr);

  char message[2000];
  if (type==TYPE_I && rd==0 && rs1==1) {
    //Log("Ret: %s(%x)", func_name, addr);
    sprintf(message, "%x: ", pc);
    strcat(message, INDENT);
    strcat(message, "Ret to %s(%x) from %s(%x);\n");
    printf(message, func_name, dnpc, curr_func_name, pc);
    //if(strlen(INDENT)>2)
    Assert(strlen(INDENT)>2, "Indentation error!");
      INDENT[strlen(INDENT)-2] = '\0';
  } else if (is_func(dnpc)){
    strcat(INDENT, "  ");

    sprintf(message, "%x: ", pc);
    strcat(message, INDENT);
    strcat(message, "Call %s(%x);\n");
    printf(message, func_name, dnpc);
  }
}

static void decode_operand(Decode *s, int *rd, word_t *src1, word_t *src2, word_t *imm, int type) {
  uint32_t i = s->isa.inst.val;
  int rs1 = BITS(i, 19, 15);
  int rs2 = BITS(i, 24, 20);
  *rd     = BITS(i, 11, 7);
  switch (type) {
    case TYPE_I: src1R();          immI(); break;
    case TYPE_U:                   immU(); break;
    case TYPE_S: src1R(); src2R(); immS(); break;
    case TYPE_J:                   immJ(); break;
    case TYPE_R: src1R(); src2R();       ; break;
    case TYPE_B: src1R(); src2R(); immB(); break;
  }
}

static int decode_exec(Decode *s) {
  int rd = 0;
  word_t src1 = 0, src2 = 0, imm = 0;
  s->dnpc = s->snpc;

#define INSTPAT_INST(s) ((s)->isa.inst.val)
#define INSTPAT_MATCH(s, name, type, ... /* execute body */ ) { \
  decode_operand(s, &rd, &src1, &src2, &imm, concat(TYPE_, type)); \
  __VA_ARGS__ ; \
}

  INSTPAT_START();
  // RV32I
  INSTPAT("??????? ????? ????? ??? ????? 00101 11", auipc  , U, R(rd) = s->pc + imm);
  INSTPAT("??????? ????? ????? 100 ????? 00000 11", lbu    , I, R(rd) = Mr(src1 + imm, 1));
  INSTPAT("??????? ????? ????? 000 ????? 01000 11", sb     , S, Mw(src1 + imm, 1, src2));
  INSTPAT("??????? ????? ????? 010 ????? 01000 11", sw     , S, Mw(src1 + imm, 4, src2));
  INSTPAT("??????? ????? ????? 000 ????? 00100 11", addi   , I, R(rd) = src1 + imm);
#define JUMP(dnpc, npc, pc, rd, rs1, snpc, type) (dnpc) = (npc); R((rd)) = snpc; IFDEF(CONFIG_FTRACE, ftrace(dnpc, pc, rd, rs1, type))
  INSTPAT("??????? ????? ????? ??? ????? 11011 11", jal    , J, JUMP(s->dnpc, s->pc + imm, s->pc, rd, BITS(s->isa.inst.val, 19, 15), s->snpc, TYPE_J));
  INSTPAT("??????? ????? ????? 000 ????? 11001 11", jalr   , I, JUMP(s->dnpc, (src1 + imm) & (~1), s->pc, rd, BITS(s->isa.inst.val, 19, 15), s->snpc, TYPE_I));

  INSTPAT("??????? ????? ????? 001 ????? 00000 11", lh     , I, R(rd) = SEXT(Mr(src1 + imm, 2), 16));
  INSTPAT("??????? ????? ????? 101 ????? 00000 11", lhu    , I, R(rd) = (word_t) Mr(src1 + imm, 2));
  INSTPAT("??????? ????? ????? 010 ????? 00000 11", lw     , I, R(rd) = SEXT(Mr(src1 + imm, 4), 32));
  INSTPAT("??????? ????? ????? 000 ????? 00000 11", lb     , I, R(rd) = SEXT(Mr(src1 + imm, 1), 8));
  INSTPAT("0000000 ????? ????? 000 ????? 01100 11", add    , R, R(rd) = src1 + src2);
  INSTPAT("0000000 ????? ????? 010 ????? 01100 11", slt    , R, R(rd) = (int64_t) SEXT(src1, 8*sizeof(word_t)) < (int64_t) SEXT(src2, 8*sizeof(word_t)));
  INSTPAT("0000000 ????? ????? 011 ????? 01100 11", sltu   , R, R(rd) = (word_t) src1 < (word_t) src2);
  INSTPAT("??????? ????? ????? 010 ????? 00100 11", slti   , I, R(rd) = (int64_t) SEXT(src1, 8*sizeof(word_t)) < (int64_t) SEXT(imm, 8*sizeof(word_t)));
  INSTPAT("??????? ????? ????? 011 ????? 00100 11", sltiu  , I, R(rd) = src1 < imm);
  INSTPAT("0000000 ????? ????? 100 ????? 01100 11", xor    , R, R(rd) = src1 ^ src2);
  INSTPAT("0000000 ????? ????? 110 ????? 01100 11", or     , R, R(rd) = src1 | src2);
  INSTPAT("??????? ????? ????? 000 ????? 11000 11", beq    , B, s->dnpc = (src1 == src2 ? s->pc + imm : s->dnpc));
  INSTPAT("??????? ????? ????? 001 ????? 11000 11", bne    , B, s->dnpc = (src1 != src2 ? s->pc + imm : s->dnpc));
  INSTPAT("??????? ????? ????? 101 ????? 11000 11", bge    , B, s->dnpc = ((int64_t) SEXT(src1, 8*sizeof(word_t)) >= (int64_t) SEXT(src2, 8*sizeof(word_t)) ? s->pc + imm : s->dnpc));
  INSTPAT("??????? ????? ????? 111 ????? 11000 11", bgeu   , B, s->dnpc = ((src1 >= src2) ? s->pc + imm : s->dnpc));
  INSTPAT("??????? ????? ????? 100 ????? 11000 11", blt    , B, s->dnpc = ((int64_t) SEXT(src1, 8*sizeof(word_t)) < (int64_t) SEXT(src2, 8*sizeof(word_t)) ? s->pc + imm : s->dnpc));
  INSTPAT("??????? ????? ????? 110 ????? 11000 11", bltu   , B, s->dnpc = src1 < src2 ? s->pc + imm : s->dnpc);

  INSTPAT("0100000 ????? ????? 000 ????? 01100 11", sub    , R, R(rd) = src1 - src2);
  INSTPAT("??????? ????? ????? 001 ????? 01000 11", sh     , S, Mw(src1 + imm, 2, src2));  
  INSTPAT("000000 0????? ????? 101 ????? 00100 11", srli   , I, R(rd) = (word_t) src1 >> (imm & 0x000000000000001FLL));//  0001 1111
  INSTPAT("000000 0????? ????? 001 ????? 00100 11", slli   , I, R(rd) = (word_t) src1 << (imm & 0x000000000000001FLL));
  INSTPAT("010000 0????? ????? 101 ????? 00100 11", srai   , I, R(rd) = (int64_t) SEXT(src1, 8*sizeof(word_t)) >> (imm & 0x000000000000001FLL));
  INSTPAT("0000000 ????? ????? 001 ????? 01100 11", sll    , R, R(rd) = (word_t) src1 << (src2 & 0x000000000000001FLL));
  INSTPAT("0100000 ????? ????? 101 ????? 01100 11", sra    , R, R(rd) = (int64_t) SEXT(src1, 8*sizeof(word_t)) >> (src2 & 0x000000000000001FLL));
  INSTPAT("0000000 ????? ????? 101 ????? 01100 11", srl    , R, R(rd) = (word_t) src1 >> (src2 & 0x000000000000001FLL));
  INSTPAT("??????? ????? ????? 111 ????? 00100 11", andi   , I, R(rd) = imm & src1);
  INSTPAT("0000000 ????? ????? 111 ????? 01100 11", and    , R, R(rd) = src1 & src2);
  INSTPAT("??????? ????? ????? 100 ????? 00100 11", xori   , I, R(rd) = src1 ^ imm);
  INSTPAT("??????? ????? ????? 110 ????? 00100 11", ori    , I, R(rd) = src1 | imm);
  INSTPAT("??????? ????? ????? ??? ????? 01101 11", lui    , U, R(rd) = imm);
  INSTPAT("0000000 00001 00000 000 00000 11100 11", ebreak , N, NEMUTRAP(s->pc, R(10))); // R(10) is $a0
  
  // RV32M
  // INSTPAT("0000001 ????? ????? 000 ????? 01100 11", mul    , R, R(rd) = src1 * src2);
  // INSTPAT("0000001 ????? ????? 001 ????? 01100 11", mulh   , R, R(rd) = (((int64_t) SEXT(src1, 8*sizeof(word_t))) * ((int64_t) SEXT(src2, 8*sizeof(word_t))) >> (8*sizeof(word_t))));
  INSTPAT("0000001 ????? ????? 000 ????? 01100 11", mul    , R, R(rd) = src1 * src2);
  INSTPAT("0000001 ????? ????? 001 ????? 01100 11", mulh   , R, R(rd) = ((int64_t) SEXT(src1, 8*sizeof(word_t))) * ((int64_t) SEXT(src2, 8*sizeof(word_t))) >> (8*sizeof(word_t)));
  INSTPAT("0000001 ????? ????? 011 ????? 01100 11", mulhu  , R, R(rd) = ((uint64_t) src1) * ((uint64_t) src2) >> (8*sizeof(word_t)));
  INSTPAT("0000001 ????? ????? 100 ????? 01100 11", div    , R, R(rd) = (int64_t) SEXT(src1, 32) / (int64_t) SEXT(src2, 32));
  INSTPAT("0000001 ????? ????? 101 ????? 01100 11", divu   , R, R(rd) = src1 / src2);
  INSTPAT("0000001 ????? ????? 110 ????? 01100 11", rem    , R, R(rd) = (int64_t) SEXT(src1, 32) % (int64_t) SEXT(src2, 32));
  INSTPAT("0000001 ????? ????? 111 ????? 01100 11", remu   , R, R(rd) = src1 % src2);

  // INSTPAT("0000001 ????? ????? 011 ????? 01100 11", mulhu  , R, R(rd) = (((uint64_t) src1 * (uint64_t) src2 >> 8*sizeof(word_t))));
  // INSTPAT("0000001 ????? ????? 100 ????? 01100 11", div    , R, R(rd) = (((int64_t) SEXT(src1, 8*sizeof(word_t))) / ((int64_t) SEXT(src2, 8*sizeof(word_t)))));
  // INSTPAT("0000001 ????? ????? 101 ????? 01100 11", divu   , R, R(rd) = (((uint64_t) src1) / ((uint64_t) src2)));
  // INSTPAT("0000001 ????? ????? 110 ????? 01100 11", rem    , R, R(rd) = (((int64_t) SEXT(src1, 8*sizeof(uint64_t))) % ((int64_t) SEXT(src2, 8*sizeof(uint64_t)))));
  // INSTPAT("0000001 ????? ????? 111 ????? 01100 11", remu   , R, R(rd) = (((uint64_t) src1) % ((uint64_t) src2)));
  
  // Privileged instructions
  INSTPAT("??????? ????? ????? 001 ????? 11100 11", csrrw  , I, R(rd) = CSR(imm); CSR(imm) = src1);

  INSTPAT("??????? ????? ????? ??? ????? ????? ??", inv    , N, INV(s->pc));
  INSTPAT_END();

  R(0) = 0; // reset $zero to 0

  return 0;
}

int isa_exec_once(Decode *s) {
  s->isa.inst.val = inst_fetch(&s->snpc, 4);
  

#ifdef CONFIG_ITRACE
  extern uint64_t g_nr_guest_inst;
  char *ring_p = s->iringbuf[g_nr_guest_inst % CONFIG_IRINGBUF_SIZE];
  ring_p += snprintf(ring_p, sizeof(s->iringbuf[g_nr_guest_inst % CONFIG_IRINGBUF_SIZE]), FMT_WORD ":", s->pc);
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&s->isa.inst.val;
  for (i = ilen - 1; i >= 0; i --) {
    ring_p += snprintf(ring_p, 4, " %02x", inst[i]);
  }
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(ring_p, ' ', space_len);
  ring_p += space_len;

#ifndef CONFIG_ISA_loongarch32r
  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(ring_p, s->iringbuf[g_nr_guest_inst % CONFIG_IRINGBUF_SIZE] + sizeof(s->iringbuf[g_nr_guest_inst % CONFIG_IRINGBUF_SIZE]) - ring_p,
      MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&s->isa.inst.val, ilen);
#else
  p[0] = '\0'; // the upstream llvm does not support loongarch32r
#endif
#endif
  return decode_exec(s);
}