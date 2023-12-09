#include "verilated.h"
#include "verilated_types.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vysyx_23060061_Top__Dpi.h"
#include <Vysyx_23060061_Top.h>
#include <Vysyx_23060061_Top___024root.h>

#include <npc.h>
#include <paddr.h>
#include <trace.h>
#include <difftest.h>

#define TOPNAME Vysyx_23060061_Top

#define MAX_INST_TO_PRINT 10

#ifdef CONFIG_WAVETRACE
static VerilatedVcdC *tfp = nullptr;
#endif
static VerilatedContext *contextp = nullptr;
static TOPNAME *top = nullptr;

// DPI-C function for `ebreak` instruction
static bool Trap = false;
void trap() { Trap = true; }

void step_and_dump_wave(){
	top->eval();
	contextp->timeInc(1);
#ifdef CONFIG_WAVETRACE
	tfp->dump(contextp->time());
#endif
}

void sim_init() {
	Verilated::traceEverOn(true);

	top = new TOPNAME;
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
	top->clk = 0b0; top->rst = 0b1; step_and_dump_wave();
	top->clk = 0b1; top->rst = 0b1; step_and_dump_wave();
	// top->clk = 0b0; top->rst = 0b0; step_and_dump_wave();
}

CPU_State get_cpu_state() {
	CPU_State cpu;

	for (int i=0; i<NR_GPR; i++) {
		cpu.gpr[i] = top->rootp->ysyx_23060061_Top__DOT__GPRs__DOT__rf[i];
	}
	cpu.pc = top->pc;
	
	return cpu;
}

CPU_State sim_init_then_reset() {

	sim_init();	
	
	reset();
	
	return get_cpu_state();	
}

void sim_exit() {
	step_and_dump_wave();
#ifdef CONFIG_WAVETRACE
	tfp->close();
#endif
}

static int inst_cnt = 0;
void exec_once() {
	
	// printf("MemRW before the next clock: %x\n", top->rootp->ysyx_23060061_Top__DOT__MemRW);
	// printf("memAddr before the next clock: %x\n", top->rootp->ysyx_23060061_Top__DOT__aluOut);
	// printf("aluOpA before the current clock: %x\n", top->rootp->ysyx_23060061_Top__DOT__aluOpA);
	// printf("aluOpB before the current clock: %x\n", top->rootp->ysyx_23060061_Top__DOT__aluOpB);
	// printf("aluOp before the current clock: %x\n", top->rootp->ysyx_23060061_Top__DOT__aluOp);
	top->clk = 0b1; top->rst = 0b0; step_and_dump_wave();

	// printf("pc = %x\n", top->pc);

	/*Difftest*/
#ifdef CONFIG_DIFFTEST
	if (inst_cnt > 0){ difftest_step(top->pc, top->ftrace_dnpc); }
#endif
	
	top->clk = 0b0; top->rst = 0b0; top->inst = pmem_read(top->pc, 4); 

#ifdef CONFIG_ITRACE
	itrace(top->pc, top->inst, 4);
#endif 
	// printf("dnpc = %x\n", top->ftrace_dnpc); // Here, dnpc equals to pc+4
	step_and_dump_wave();
	
	if(top->pc == 0x80001304){
		top->clk = 0b1; top->rst = 0b0; step_and_dump_wave();	
		
		// print("aluOut: %x", top->rootp->ysyx)
		top->clk = 0b0; top->rst = 0b0; top->inst = pmem_read(top->pc, 4);  step_and_dump_wave();
		printf("mcause: %x\n", top->rootp->ysyx_23060061_Top__DOT__CSRs__DOT__rf[3]);
		printf("pc: %x\n", top->pc);
		exit(0);
	}


#ifdef CONFIG_FTRACE
	ftrace(top->inst, top->ftrace_dnpc, top->pc);
#endif

	inst_cnt ++;
}

void execute(uint64_t n) {
	for ( ;n > 0; n --) {
		exec_once();
		if (Trap) { 
			if (top->rootp->ysyx_23060061_Top__DOT__GPRs__DOT__rf[10]==0)
				printf("HIT GOOD TRAP\n");
			else
				printf("HIT BAD TRAP\n");
			sim_exit();
			break; 
		}
	}
	// sim_exit();
	// exit(0);
}

void npc_exec(uint64_t n) {
	// TODO: set npc state
	
	execute(n);

	// TODO: check npc state
}

void reg_display() {
	const int num_regs = 32;
	VlUnpacked<IData/*31:0*/, num_regs> rf = top->rootp->ysyx_23060061_Top__DOT__GPRs__DOT__rf;
	
	int i;
	for (i=0; i<num_regs; i++){
		printf("reg[%d] = %x\n", i, rf[i]);
	}
}