// #include <stdio.h>

// int main() {
//   printf("Hello, ysyx!\n");
//   return 0;
// }


#include <nvboard.h>
#include <Vtop.h>

static TOP_NAME dut;

void nvboard_bind_all_pins(Vtop* top);

static void single_cycle() {
  dut.a = rand() & 1;
  dut.b = rand() & 1;
}

int main() {
  nvboard_bind_all_pins(&dut);
  nvboard_init();

  while(1) {
    nvboard_update();
    single_cycle();
  }
}

