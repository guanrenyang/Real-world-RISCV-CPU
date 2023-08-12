#include "verilated.h"
#include "verilated_vcd_c.h"

#include <nvboard.h>

#include <Vbarrel_shifter.h>

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;

static Vbarrel_shifter* top;

void nvboard_bind_all_pins(Vbarrel_shifter* top);

void step_and_dump_wave(){
    top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
}

void sim_init(){
    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;
    top = new Vbarrel_shifter;

    contextp->traceEverOn(true);
    top->trace(tfp, 0);
    tfp->open("dump.vcd");
}

void sim_exit(){
    step_and_dump_wave();
    tfp->close();
}

int main(){
    
    top = new Vbarrel_shifter;
    nvboard_bind_all_pins(top);
    nvboard_init();

    while (1)
    {
        nvboard_update();
        top->eval();
    }
    
    // sim_init();
    
    // top->clk = 0b1;  step_and_dump_wave();
    // top->clk = 0b0;  step_and_dump_wave();
    // top->clk = 0b1;  step_and_dump_wave();
    // top->clk = 0b0;  step_and_dump_wave();

    // sim_exit();

}
