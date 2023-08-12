/*Experiment 1*/
#include <nvboard.h>

#include "verilated.h"
#include "verilated_vcd_c.h"

#include <Vmux41.h>

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;

static Vmux41* top;

void nvboard_bind_all_pins(Vmux41* top);

void step_and_dump_wave(){
    top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
}

void sim_init(){
    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;
    top = new Vmux41;
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

    nvboard_bind_all_pins(top);
    nvboard_init();

    while (1)
    {   
        nvboard_update();
        step_and_dump_wave();
    }
    
    // top->y=  0b00; top->x[0] = 0b00; top->x[1] = 0b01; top->x[2] = 0b10, top->x[3] = 0b11; step_and_dump_wave();
    // top->y=  0b01; top->x[0] = 0b00; top->x[1] = 0b01; top->x[2] = 0b10, top->x[3] = 0b11; step_and_dump_wave();
    // top->y=  0b10; top->x[0] = 0b00; top->x[1] = 0b01; top->x[2] = 0b10, top->x[3] = 0b11; step_and_dump_wave();
    // top->y=  0b11; top->x[0] = 0b00; top->x[1] = 0b01; top->x[2] = 0b10, top->x[3] = 0b11; step_and_dump_wave();


    sim_exit();
}

