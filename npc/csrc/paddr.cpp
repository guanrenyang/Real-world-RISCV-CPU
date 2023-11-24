#include <paddr.h>

static uint8_t *instMem = NULL;

extern char *img_file;

void init_mem() {
	instMem = (uint8_t*) malloc(MEMSIZE);
}

uint8_t* guest_to_host(uint32_t paddr) { return  instMem + paddr - MEMBASE; }

uint32_t host_read(void *addr, int len) {
	switch (len) {
		case 1: return *(uint8_t  *)addr;
		case 2: return *(uint16_t *)addr;
		case 4: return *(uint32_t *)addr;
	}
}

void host_write(void *addr, int len, uint32_t data) {
  switch (len) {
    case 1: *(uint8_t  *)addr = data; return;
    case 2: *(uint16_t *)addr = data; return;
    case 4: *(uint32_t *)addr = data; return;
  }
}

uint32_t paddr_read(uint32_t paddr, int len) {
  assert(guest_to_host(paddr) < (instMem + MEMSIZE));

  // uint32_t ret = *(uint32_t*)(instMem + paddr - MEMBASE); // right
  uint32_t ret = host_read(guest_to_host(paddr), len);

  printf("\n[paddr_read]: %x at addr %x\n", ret, paddr);
  return ret;
}



void paddr_write(uint32_t paddr, int len, uint32_t data) {
  assert(guest_to_host(paddr) < (instMem + MEMSIZE));

  host_write(guest_to_host(paddr), len, data);
  
  printf("\n[pmem_write]: write data %x at addr %x\n", data, paddr);
}

extern "C" void pmem_read(int raddr, int *rdata, char rmask) {
  int bitMask = ((rmask & 1) * 0xFF) | ((((rmask & 2) >> 1)* 0xFF) << 8) | ((((rmask & 4) >> 2 ) * 0xFF) << 16) | ((((rmask & 8) >> 3 ) * 0xFF) << 24);
  (*rdata) = paddr_read(raddr, 4) & bitMask;
  // printf("renyang: %x\n", *rdata);
}

extern "C" void pmem_write(int waddr, int wdata, char wmask){
  // printf("renyang: %x\n", wdata);
  int bitMask = ((wmask & 1) * 0xFF) | ((((wmask & 2) >> 1)* 0xFF) << 8) | ((((wmask & 4) >> 2 ) * 0xFF) << 16) | ((((wmask & 8) >> 3 ) * 0xFF) << 24);
  paddr_write(waddr, 4, wdata & bitMask);	
}