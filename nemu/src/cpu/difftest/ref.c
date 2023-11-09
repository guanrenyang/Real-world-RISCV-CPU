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

#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

struct diff_context_t {
	word_t gpr[RISCV_GPR_NUM];
	vaddr_t pc;
};

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (direction == DIFFTEST_TO_REF) {
	memcpy(guest_to_host(addr), buf, n);
  } else if (direction == DIFFTEST_TO_DUT) {
	memcpy(buf, guest_to_host(addr), n);
  }
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  if(direction == DIFFTEST_TO_DUT) {	
	struct diff_context_t* ctx = (struct diff_context_t*)dut;
	for(int i=0;i<RISCV_GPR_NUM;i++){
		ctx->gpr[i] = cpu.gpr[i];	
	}	
	printf("pc = %x\n", cpu.pc);
	ctx->pc = cpu.pc;

  } else if (direction == DIFFTEST_TO_REF) {
	struct diff_context_t* ctx = (struct diff_context_t*)dut;	
	for (int i = 0; i < RISCV_GPR_NUM; i++) {
		cpu.gpr[i] = ctx->gpr[i];
	}
	
	cpu.pc = ctx->pc;
  }
}

__EXPORT void difftest_exec(uint64_t n) {
	cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
