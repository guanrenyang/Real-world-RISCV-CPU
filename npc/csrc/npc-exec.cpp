#include "verilated.h"
#include "verilated_types.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"

#include "VysyxSoCFull__Dpi.h"
#include <VysyxSoCFull.h>
#include <VysyxSoCFull___024root.h>

#include <npc.h>
#include <paddr.h>
#include <trace.h>
#include <difftest.h>

#define MAX_INST_TO_PRINT 10

#define PC_ top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc
#define GPRs_ top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__GPRs__DOT__rf
// #define DNPC_ top->rootp->ftrace_dnpc

#ifdef CONFIG_WAVETRACE
static VerilatedVcdC *tfp = nullptr;
#endif

int EXEC_CODE = SUCCESS;

static VerilatedContext *contextp = nullptr;
static TOP_NAME *top = nullptr;

static int cycle_cnt = 0;
static uint32_t pc_old;

// DPI-C function for `ebreak` instruction
void trap() { EXEC_CODE = Trap; }

void step_and_dump_wave(){
	top->eval();
	contextp->timeInc(1);
#ifdef CONFIG_WAVETRACE
	tfp->dump(contextp->time());
#endif
}

void sim_init(int argc, char *argv[]) {
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	top = new TOP_NAME;
	contextp = new VerilatedContext;
#ifdef CONFIG_WAVETRACE
	tfp = new VerilatedVcdC;
#endif

	contextp->traceEverOn(true);
#ifdef CONFIG_WAVETRACE
	top->trace(tfp, 0);
	tfp->open("./build/dump.vcd");
#endif
}

void reset() {
	top->clock = 0b0; top->reset = 0b1; step_and_dump_wave();
	top->clock = 0b1; top->reset = 0b1; step_and_dump_wave();
	// top->clock = 0b0; top->reset = 0b0; step_and_dump_wave();
}


CPU_State get_cpu_state() {
	CPU_State cpu;

	for (int i=0; i<NR_GPR; i++) {
		cpu.gpr[i] = GPRs_[i];
	}
	cpu.pc = PC_;
	
	return cpu;
}

CPU_State sim_init_then_reset(int argc, char *argv[]) {

	sim_init(argc, argv);	
	
	reset();
	
#ifdef CONFIG_DIFFTEST
	pc_old = PC_;
#endif
	return get_cpu_state();	
}

void sim_exit() {
	step_and_dump_wave();
	printf("Total cycles executed: %d\n", cycle_cnt);
#ifdef CONFIG_WAVETRACE
	tfp->close();
#endif
}


void exec_once() {

	// printf("MemRW before the next clock: %x\n", top->rootp->ysyx_23060061__DOT__MemRW);
	// printf("memAddr before the next clock: %x\n", top->rootp->ysyx_23060061__DOT__aluOut);
	// printf("aluOpA before the current clock: %x\n", top->rootp->ysyx_23060061__DOT__aluOpA);
	// printf("aluOpB before the current clock: %x\n", top->rootp->ysyx_23060061__DOT__aluOpB);
	// printf("aluOp before the current clock: %x\n", top->rootp->ysyx_23060061__DOT__aluOp);
	// printf("pc: %x, ra: %x\n", top->rootp->ysyx_23060061__DOT__pc, top->rootp->ysyx_23060061__DOT__CSRs__DOT__rf[1]);
	top->clock = 0b1; top->reset = 0b0; step_and_dump_wave();

	// printf("pc = %x\n", PC_);
	// if (cycle_cnt == 1000) {
	// 	sim_exit();
	// 	exit(0);
	// }
	/*Difftest*/
#ifdef CONFIG_DIFFTEST
	if (PC_ != pc_old){ 
		uint32_t inst_old = pmem_read(pc_old, 4);
		// difftest_step(PC_, DNPC_, (inst_old & 0x0000007f) == 0x23); 
		difftest_step(PC_, DNPC_, false);
	}
#endif
	
	top->clock = 0b0; top->reset = 0b0; // top->inst = pmem_read(top->pc, 4); 

#ifdef CONFIG_ITRACE
	if(PC_!=pc_old)
		itrace(PC_, pmem_read(PC_, 4), 4);
#endif 
	// printf("dnpc = %x\n", top->ftrace_dnpc); // Here, dnpc equals to pc+4
	step_and_dump_wave();
	
	// static int sb_cnt = 0;
	// if(pc_old == 0x80001084)
	// 	sb_cnt ++;
	// if(sb_cnt == 60){
	// 	printf("sb_cnt: %d\n", sb_cnt);
	// 	top->clock = 0b1; top->reset = 0b0; step_and_dump_wave();	
	// 	
	// 	sim_exit();
	// 	exit(0);
	// }

#ifdef CONFIG_FTRACE
	if(PC_!=pc_old)
		ftrace(pmem_read(PC_, 4), DNPC_, PC_);
#endif

	cycle_cnt ++;
	pc_old = PC_;
}

void execute(uint64_t n) {
	for ( ;n > 0; n --) {
		exec_once();
		// printf("EXEC_CODE: %d\n", EXEC_CODE);
		switch (EXEC_CODE) {
			case Trap:
				if (GPRs_[10]==0)
					printf("HIT GOOD TRAP\n");
				else
					printf("HIT BAD TRAP\n");
				sim_exit();
				break;
			case BAD_TIMER_IO:
				printf("BAD TIMER IO ADDRESS\n");
				// printf("SRAM state: %x\n", top->rootp->Top__DOT__SRAM__DOT__state);
				sim_exit();
				assert(NULL);
				break;
		}
		if (EXEC_CODE == Trap) { 
			break; 
		}
	}
}

void npc_exec(uint64_t n) {
	// TODO: set npc state
	
	execute(n);

	// TODO: check npc state
}

void reg_display() {
	const int num_regs = 32;
	VlUnpacked<IData/*31:0*/, num_regs> rf = GPRs_;
	
	int i;
	for (i=0; i<num_regs; i++){
		printf("reg[%d] = %x\n", i, rf[i]);
	}
}