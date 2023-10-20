#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#define MEMBASE 0x80000000
#define MEMSIZE 0x8000000

static uint8_t *instMem = NULL;

extern char *img_file;
uint8_t* guest_to_host(uint32_t paddr) { return  instMem + paddr - MEMBASE; }

// Memory
// = {
//   0b00000000000100000000000010010011,
//   0b00000000000100001000000010010011,
//   0b00000000000100001000000010010011,
//   0b00000000000100001000000010010011,
//   0b00000000000000000000000001110011
// }; 


void init_mem() {
	instMem = (uint8_t*) malloc(MEMSIZE);
	// instMem = new uint8_t [MEMSIZE];
}

uint32_t host_read(void *addr, int len){
	switch (len) {
		case 1: return *(uint8_t  *)addr;
		case 2: return *(uint16_t *)addr;
		case 4: return *(uint32_t *)addr;
	}
}
uint32_t paddr_read(uint32_t paddr){
  assert(guest_to_host(paddr) < (instMem + MEMSIZE));
  // uint32_t ret = host_read(guest_to_host(paddr), 4);
  // uint32_t ret = host_read(instMem+paddr - MEMBASE, 4);
  uint32_t ret = *(uint32_t*)(instMem + paddr - MEMBASE); // right
  printf("inst: %x at addr %x\n", ret, paddr);
  return ret;
}

