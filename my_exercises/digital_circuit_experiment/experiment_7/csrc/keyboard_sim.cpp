#include "verilated.h"
#include "verilated_vcd_c.h"

#define TOPNAME Vkeyboard_sim

#include <Vkeyboard_sim.h>

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;

static TOPNAME* top;

void step_and_dump_wave(){
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

void sim_init(){
    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;
    top = new TOPNAME;

    contextp->traceEverOn(true);
    top->trace(tfp, 0);
    tfp->open("dump.vcd");   
}

void sim_exit(){
    step_and_dump_wave();
    tfp->close();
}

int main(){
    sim_init();
    
    while (!contextp->gotFinish()) {
      step_and_dump_wave(); 
    }

    sim_exit();
    
    return 0;
}

