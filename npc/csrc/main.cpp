/*LED*/
#include <nvboard.h>
#include <Vtop.h>

static TOP_NAME dut;

void nvboard_bind_all_pins(Vtop* top);

static void single_cycle() {
  dut.clk = 0; dut.eval();
  dut.clk = 1; dut.eval();
}

static void reset(int n) {
  dut.rst = 1;
  while (n -- > 0)
    single_cycle();
  dut.rst = 0;
}

int main() {
  nvboard_bind_all_pins(&dut);
  nvboard_init();

  reset(10);

  while (1)
  {
    nvboard_update();
    single_cycle();
  }
  
}
/* example*/
// #include <stdio.h>

// int main() {
//   printf("Hello, ysyx!\n");
//   return 0;
// }

/* On-off Switch*/
// #include <nvboard.h>
// #include <Vtop.h>

// static TOP_NAME dut;

// void nvboard_bind_all_pins(Vtop* top);

// static void single_cycle() {
//   dut.eval();
//   printf("a: %d, b: %d, f: %d", dut.a, dut.b, dut.f);
// }

// int main() {
//   nvboard_bind_all_pins(&dut);
//   nvboard_init();

//   while(1) {
//     nvboard_update();
//     single_cycle();
//   }
// }

