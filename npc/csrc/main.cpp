#include "verilated.h"
#include "verilated_vcd_c.h"
#include <inttypes.h>
#include "svdpi.h"
#include <stdlib.h>
#include "Vysyx_23060061_Top__Dpi.h"
#include <Vysyx_23060061_Top.h>
#include <getopt.h>
#include <stdio.h>

#define TOPNAME Vysyx_23060061_Top
#define RESET_VECTOR 0x80000000

char *log_file = NULL;
char *img_file = NULL;
extern uint8_t *instMem;

uint32_t paddr_read(uint32_t paddr);
uint8_t* guest_to_host(uint32_t paddr);
void init_mem();

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"log"      , required_argument, NULL, 'l'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-l:", table, NULL)) != -1) {
    switch (o) {
      case 'l': log_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

static long load_img() {
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  // Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  
  fseek(fp, 0, SEEK_SET); 
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  // Assert(ret == 1, "fread failed");

  fclose(fp);
  return size;
}



bool Trap = false;
void trap() {
  Trap = true;
}

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

int main(int argc, char **argv) {

  parse_args(argc, argv);

  init_mem();	
  
  long size = load_img();

  Verilated::traceEverOn(true);
  sim_init();
  
  // cycle 1 
  top->clk = 0b0; top->rst = 0b1; step_and_dump_wave();
  top->clk = 0b1; top->rst = 0b1; step_and_dump_wave();
  top->clk = 0b0; top->rst = 0b1; step_and_dump_wave();

  // // cycle 2
  // top->clk = 0b1; top->rst = 0b0; step_and_dump_wave();
  // top->clk = 0b0; top->rst = 0b0; step_and_dump_wave();
  printf("pc: %x\n", top->pc);
  // cycle 2
  while(!Trap){
    top->clk = 0b1; top->rst = 0b0; step_and_dump_wave(); printf("pc: %x\n", top->pc);
    top->clk = 0b0; top->rst = 0b0; top->inst = paddr_read(top->pc); step_and_dump_wave(); printf("pc: %x\n", top->pc);

  }
 //  top->clk = 0b1; top->rst = 0b0; step_and_dump_wave();
 //  top->clk = 0b0; top->rst = 0b0; top->inst = paddr_read(top->pc); step_and_dump_wave();
 //  
 //  //cycle 3 
 //  top->clk = 0b1; top->rst = 0b0; step_and_dump_wave();
 //  top->clk = 0b0; top->rst = 0b0; top->inst = 0b00000000000100001000000010010011; step_and_dump_wave();
 // 
 //  //cycle 4 
 //  top->clk = 0b1; top->rst = 0b0; step_and_dump_wave();
 //  top->clk = 0b0; top->rst = 0b0; top->inst = 0b00000000000100001000000010010011; step_and_dump_wave();

  sim_exit();

  return 0;
}
