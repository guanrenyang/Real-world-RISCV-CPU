// /*Experiment 2*/
// #include "verilated.h"
// #include "verilated_vcd_c.h"

// #include <Vencode42.h>

// VerilatedContext* contextp = NULL;
// VerilatedVcdC* tfp = NULL;

// static Vencode42* top;

// void step_and_dump_wave(){
//     top->eval();
//     contextp->timeInc(1);
//     tfp->dump(contextp->time());
// }

// void sim_init(){
//     contextp = new verilatedcontext;
//     tfp = new verilatedvcdc;
//     top = new vencode42;
//     contextp->traceeveron(true);
//     top->trace(tfp, 0);
//     tfp->open("dump.vcd");   
// }

// void sim_exit(){
//     step_and_dump_wave();
//     tfp->close();
// }

// int main(){
//     sim_init();

//     top->en=0b1; top->x = 0b0001; step_and_dump_wave();
//                  top->x = 0b0010; step_and_dump_wave();
//                  top->x = 0b0100; step_and_dump_wave();
//                  top->x = 0b1000; step_and_dump_wave();
//     top->en=0b1; top->x = 0b0101; step_and_dump_wave();
//                  top->x = 0b0110; step_and_dump_wave();
//                  top->x = 0b0111; step_and_dump_wave();
//                  top->x = 0b1000; step_and_dump_wave();

//     top->en=0b0; top->x = 0b0001; step_and_dump_wave();
//                  top->x = 0b0010; step_and_dump_wave();
//                  top->x = 0b0100; step_and_dump_wave();
//                  top->x = 0b1000; step_and_dump_wave();
     
            

//     sim_exit();
// }

