// #include "verilated.h"
// #include "verilated_vcd_c.h"

// #include <Vadder1b.h>

// VerilatedContext* contextp = nullptr;
// VerilatedVcdC* tfp = nullptr;
// Vadder1b* top = nullptr;

// void step_and_dump_wave(){
//     top->eval();
//     contextp->timeInc(1);
//     tfp->dump(contextp->time());
// }

// void sim_init(){
//     contextp = new VerilatedContext;
//     tfp = new VerilatedVcdC;
//     top = new Vadder1b;
//     contextp->traceEverOn(true);
//     top->trace(tfp, 0);
//     tfp->open("dump.vcd");   
// }

// void sim_exit(){
//     step_and_dump_wave();
//     tfp->close();
// }

// int main(){
//     sim_init();
    
//     for (int count_1=0; count_1<2; count_1++){
//         if (count_1==0)
//             top->a_i = 0b0;
//         else
//             top->a_i = 0b1;

//         for (int count_2=0;count_2<2;count_2++){
//             if (count_2==0)
//                 top->b_i = 0b0;
//             else
//                 top->b_i = 0b1;
            
//             for (int count_3=0;count_3<2;count_3++){
//                 if (count_3==0)
//                     top->c_i = 0b0;
//                 else
//                     top->c_i = 0b1;
//                 step_and_dump_wave();
//             }
//         }
//     }
//     // nvboard_bind_all_pins(top);
//     // nvboard_init();

//     // while (1)
//     // {
//     //     nvboard_update();
//     //     top->eval();
//     // }
    
    

//     sim_exit();
// }

