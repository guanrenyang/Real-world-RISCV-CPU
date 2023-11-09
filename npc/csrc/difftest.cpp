#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <difftest-def.h>
#include <dlfcn.h>
#include <paddr.h>
#include <npc.h>
#include <iostream>
void (*ref_difftest_memcpy)(uint32_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

void init_difftest(char *ref_so_file, long img_size, int port) {
	assert(ref_so_file != NULL);	
	
	void *handle;
	handle = dlopen(ref_so_file, RTLD_LAZY);
	assert(handle);	
	
	ref_difftest_memcpy = (void (*)(uint32_t, void *, size_t, bool))dlsym(handle, "difftest_memcpy");
	assert(ref_difftest_memcpy);
	
	ref_difftest_regcpy = (void (*)(void *, bool))dlsym(handle, "difftest_regcpy");
	assert(ref_difftest_regcpy);

	ref_difftest_exec = (void (*)(uint64_t))dlsym(handle, "difftest_exec");
	assert(ref_difftest_exec);

	void (*ref_difftest_init)(int) = (void (*)(int))dlsym(handle, "difftest_init");
	assert(ref_difftest_init);
	
	printf("Differential testing on");

	ref_difftest_init(port);
	ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);

	CPU_State cpu = get_cpu_state();
	ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

static bool checkregs(const CPU_State* ref_state, uint32_t npc) {
	CPU_State cpu = get_cpu_state();

	for (int i=0; i<NR_GPR; i++) {
		printf("cpu.gpr[%d]=%x, ref_state->gpr[%d]=%x", i, cpu.gpr[i], i, ref_state->gpr[i]);
		if(ref_state->gpr[i] != cpu.gpr[i])
			return false;
	}	

	// printf("pc = %x, npc = %x\n", ref_state->pc, npc);
	// int t;
	// std::cin >> t;
	if(ref_state->pc != npc)
		return false;	

	return true;
}

void difftest_step(uint32_t pc, uint32_t npc) {
	ref_difftest_exec(1);
	
	CPU_State ref_state;
	ref_difftest_regcpy(&ref_state, DIFFTEST_TO_DUT);
	
	if(!checkregs(&ref_state, npc)){
		fprintf(stderr, "difftest failed with npc=%x, ref_state->pc=%x\n", npc, ref_state.pc);
		assert(0);
	}
}