#include <nvboard.h>
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <Vkey_monitor.h>

#define TOPNAME Vkey_monitor

VerilatedContext* contextp = NULL;
static TOPNAME* top;

void nvboard_bind_all_pins(TOPNAME* top);

int main(){
    
    top = new TOPNAME;

    nvboard_bind_all_pins(top);
    nvboard_init();
  
    top->clk = 0;
    top->clrn = 0;
    while (1)
    { 
        top->clrn = 1;
        top->clk = !top->clk;
        nvboard_update();
        top->eval();

    }

    delete top;
    return 0;
}

