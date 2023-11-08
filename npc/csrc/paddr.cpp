#include <paddr.h>

static uint8_t *instMem = NULL;

extern char *img_file;

void init_mem() {
	instMem = (uint8_t*) malloc(MEMSIZE);
}

uint8_t* guest_to_host(uint32_t paddr) { return  instMem + paddr - MEMBASE; }

uint32_t host_read(void *addr, int len){
	switch (len) {
		case 1: return *(uint8_t  *)addr;
		case 2: return *(uint16_t *)addr;
		case 4: return *(uint32_t *)addr;
	}
}

uint32_t paddr_read(uint32_t paddr, int len){
  assert(guest_to_host(paddr) < (instMem + MEMSIZE));

  // uint32_t ret = *(uint32_t*)(instMem + paddr - MEMBASE); // right
  uint32_t ret = host_read(guest_to_host(paddr), len);

  printf("[paddr_read] inst: %x at addr %x\n", ret, paddr);
  return ret;
}

