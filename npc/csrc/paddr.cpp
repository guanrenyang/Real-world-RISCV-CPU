#include <paddr.h>
#include <utils.h>
#include <npc.h>
static uint8_t instMem[MEMSIZE] __attribute((aligned(4096))) = {};

extern char *img_file;

void init_mem() {
}

uint8_t* guest_to_host(uint32_t paddr) { return  instMem + paddr - MEMBASE; }

uint32_t host_read(void *addr, int len) {
	assert(len == 1 || len == 2 || len == 4);
	switch (len) {
		case 1: return *(uint8_t  *)addr;
		case 2: return *(uint16_t *)addr;
		case 4: return *(uint32_t *)addr;
	}
}

void host_write(void *addr, int len, uint32_t data) {
	assert(len == 1 || len == 2 || len == 4);
  	switch (len) {
    	case 1: *(uint8_t  *)addr = data; return;
    	case 2: *(uint16_t *)addr = data; return;
    	case 4: *(uint32_t *)addr = data; return;
  	}
}

uint32_t pmem_read(uint32_t paddr, int len) {
  assert(guest_to_host(paddr) < (instMem + MEMSIZE));

  // uint32_t ret = *(uint32_t*)(instMem + paddr - MEMBASE); // right
  uint32_t ret = host_read(guest_to_host(paddr), len);

  // printf("\n[pmem_read]: %x at addr %x\n", ret, paddr);
  return ret;
}

void pmem_write(uint32_t paddr, int len, uint32_t data) {
  assert(guest_to_host(paddr) < (instMem + MEMSIZE));

  host_write(guest_to_host(paddr), len, data);
  
  // printf("\n[paddr_write]: write data %x at addr %x\n", data, paddr);
}
static bool in_pmem(uint32_t paddr) {
  return MEMBASE <= paddr && paddr < MEMBASE + MEMSIZE;
}

static uint32_t htime = 0;
static bool ltime_valid = false;
extern "C" void paddr_read(int raddr, int *rdata) {

  if (in_pmem(raddr)) {
	(*rdata) = pmem_read(raddr, 4);
	printf("paddr_read: %x, %x\n", raddr, *rdata);
	return;
  } 

  if (raddr == RTC_MMIO) {
	assert(!ltime_valid);

	uint64_t us = get_time();	
	(*rdata) = (uint32_t)us;
	htime = (uint32_t)(us >> 32);
	
	ltime_valid = true;
  } else if (raddr == (RTC_MMIO + 4)) {
	assert(ltime_valid);

	(*rdata) = htime;
	
	ltime_valid = false;
  } else {
	extern int EXEC_CODE;
	EXEC_CODE = BAD_TIMER_IO;
	printf("Bad Address: %x\n", raddr);
  }
}

extern "C" void paddr_write(int waddr, int wdata, char wmask){

  printf("paddr_write: %x, %x, %x\n", waddr, wdata, wmask);

  if (in_pmem(waddr)) {
	wdata &= ((wmask & 1) * 0xFF) | ((((wmask & 2) >> 1)* 0xFF) << 8) | ((((wmask & 4) >> 2 ) * 0xFF) << 16) | ((((wmask & 8) >> 3 ) * 0xFF) << 24);
    // int bitMask = ((wmask & 1) * 0xFF) | ((((wmask & 2) >> 1)* 0xFF) << 8) | ((((wmask & 4) >> 2 ) * 0xFF) << 16) | ((((wmask & 8) >> 3 ) * 0xFF) << 24);
	int len = wmask == 1 ? 1 : (wmask == 3 ? 2 : (wmask == 15 ? 4 : -1));
	assert(len!=-1);
	pmem_write(waddr, len, wdata);	
	return;
  } 
  
  assert(waddr == SERIAL_MMIO && wmask == 1);
  putc((char)wdata, stderr);
}