#ifndef __NPC_H__
#define __NPC_H__
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

CPU_State sim_init_then_reset(int argc, char *argv[]);
void sim_exit();

CPU_State get_cpu_state();
void reg_display();

enum { SUCCESS = 0, Trap, BAD_TIMER_IO};

#endif