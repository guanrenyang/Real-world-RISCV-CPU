//#include "verilated.h"
//#include "verilated_vcd_c.h"
//
//#include <Vadder4b.h>
//
//VerilatedContext* contextp = nullptr;
//VerilatedVcdC* tfp = nullptr;
//Vadder4b* top = nullptr;
//
//void step_and_dump_wave(){
//    top->eval();
//    contextp->timeInc(1);
//    tfp->dump(contextp->time());
//}
//
//void sim_init(){
//    contextp = new VerilatedContext;
//    tfp = new VerilatedVcdC;
//    top = new Vadder4b;
//    contextp->traceEverOn(true);
//    top->trace(tfp, 0);
//    tfp->open("dump.vcd");   
//}
//
//void sim_exit(){
//    step_and_dump_wave();
//    tfp->close();
//}
//
//void single_cycle(){
//    top->clk = !top->clk;
//    step_and_dump_wave();
//    top->clk = !top->clk;
//    step_and_dump_wave();
//}
//int main(){
//    sim_init();
//    
//    top->reset = 0b0;
//    top->clk = 0b0;
//    for(int cycle=0;cycle<=5;cycle++){
//        top->A1 = 0b0011;
//        top->B1 = 0b0001;
//        single_cycle();
//    }
//    // nvboard_bind_all_pins(top);
//    // nvboard_init();
//
//    // while (1)
//    // {
//    //     nvboard_update();
//    //     top->eval();
//    // }
//    
//    
//
//    sim_exit();
//}
//
