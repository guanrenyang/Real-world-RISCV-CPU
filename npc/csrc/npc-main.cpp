#include <npc.h>

void init_monitor(int, char *[]);
void sdb_mainloop();

int main(int argc, char *argv[]) {
  init_monitor(argc, argv);
  
  sdb_mainloop();

  return 0;
}