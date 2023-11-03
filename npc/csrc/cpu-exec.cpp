#include "verilated.h"
#include "verilated_types.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vysyx_23060061_Top__Dpi.h"
#include <Vysyx_23060061_Top.h>
#include <Vysyx_23060061_Top___024root.h>

#include <npc.h>
#include <paddr.h>

#define TOPNAME Vysyx_23060061_Top

#define MAX_INST_TO_PRINT 10

static VerilatedVcdC *tfp = nullptr;
static VerilatedContext *contextp = nullptr;
static TOPNAME *top = nullptr;

static bool Trap = false;
void trap() { Trap = true; }

void sim_init() {

	Verilated::traceEverOn(true);

	top = new TOPNAME;
	contextp = new VerilatedContext;
	tfp = new VerilatedVcdC;

	contextp->traceEverOn(true);
	top->trace(tfp, 0);
	tfp->open("./build/dump.vcd");
}

void step_and_dump_wave(){
	top->eval();
	contextp->timeInc(1);
	tfp->dump(contextp->time());
}


void reset() {
	top->clk = 0b0; top->rst = 0b1; step_and_dump_wave();
	top->clk = 0b1; top->rst = 0b1; step_and_dump_wave();
	top->clk = 0b0; top->rst = 0b1; step_and_dump_wave();
}

void sim_exit() {
	step_and_dump_wave();
	tfp->close();
}

void exec_once() {
	top->clk = 0b1; top->rst = 0b0; step_and_dump_wave();
	top->clk = 0b0; top->rst = 0b0; top->inst = paddr_read(top->pc, 4); step_and_dump_wave();
}

void execute(uint64_t n) {
	for ( ;n > 0; n --) {
		exec_once();
		if (Trap) { 
			printf("HIT TRAP\n");
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
	VlUnpacked<IData/*31:0*/, num_regs> rf = top->rootp->ysyx_23060061_Top__DOT__registerFile__DOT__rf;
	
	int i;
	for (i=0; i<num_regs; i++){
		printf("reg[%d] = %x\n", i, rf[i]);
	}
}