#include <stdio.h>
#include <stdlib.h>
#include <assert.h>	
#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
int main(int argc, char** argv) {

    Verilated::mkdir("logs");

    VerilatedContext* contextp = new VerilatedContext;
    VerilatedVcdC* tfp = new VerilatedVcdC;

    contextp->traceEverOn(true);

    contextp->commandArgs(argc, argv);

    Vtop* top = new Vtop{contextp};

    top->trace(tfp, 99);
    
    tfp->open("obj_dir/simx.vcd");

    while (contextp->time()<10 && !contextp->gotFinish()) {
        contextp->timeInc(1);

        int a = rand() & 1;
        int b = rand() & 1; 
        top->a = a;
        top->b = b; 

        top->eval();
        tfp->dump(contextp->time());
	    printf("a = %d, b = %d, f = %d\n", a, b, top->f);    
	    assert(top->f == (a ^ b));
    }   

    top->final();
    tfp->close();

    delete top;
    delete contextp;
    return 0;
}
