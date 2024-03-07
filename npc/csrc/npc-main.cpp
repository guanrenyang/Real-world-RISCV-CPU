#include <npc.h>
#include <cassert>
#include <cstdio>

extern "C" void flash_read(uint32_t addr, uint32_t *data) { assert(0); }



void init_monitor(int, char *[]);
void sdb_mainloop();

int main(int argc, char *argv[]) {
  init_monitor(argc, argv);
  
  sdb_mainloop();

  return 0;
}