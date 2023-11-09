#include <macro.h>
#include <stdint.h>

#ifdef CONFIG_RVE
#define NR_GPR 16
#else
#define NR_GPR 32
#endif

struct CPU_State {
	uint32_t gpr[NR_GPR];
	uint32_t pc;
};

void npc_exec(uint64_t n);

CPU_State sim_init_then_reset();
void sim_exit();

void reg_display();