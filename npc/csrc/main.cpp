#include "verilated.h"
#include "verilated_vcd_c.h"

#include <Vysyx_23060061_Top.h>

#define TOPNAME Vysyx_23060061_Top

VerilatedVcdC* tfp = nullptr;
VerilatedContext* contextp = NULL;
static TOPNAME* top;

void step_and_dump_wave(){
    top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
}

void sim_init(){
    top = new TOPNAME;

    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;

    contextp->traceEverOn(true);
    top->trace(tfp, 0);
    tfp->open("./build/dump.vcd");
}

void sim_exit(){
    step_and_dump_wave();
    tfp->close();
}

int main() {
  sim_init();

  top->clk = 0b1; top->rst = 0b1; step_and_dump_wave();
  top->clk = 0b0; step_and_dump_wave();

  top->clk = 0b1; top->rst = 0b0; step_and_dump_wave();
  top->clk = 0b0; top->rst = 0b0; top->eval();
  printf("pr: %x\n", top->pc);
  top->inst = 0b00000000000100000000000010011011; step_and_dump_wave();
  
  sim_exit();

  return 0;
}
