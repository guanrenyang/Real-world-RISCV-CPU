#ifndef __PADDR_H__
#define __PADDR_H__

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <macro.h>

uint8_t* guest_to_host_pmem(uint32_t paddr);
uint8_t* guest_to_host_mrom(uint32_t paddr);
uint8_t* guest_to_host_flash(uint32_t paddr);
uint8_t* guest_to_host(uint32_t paddr);

inline bool in_pmem(uint32_t paddr) {
  return MEMBASE <= paddr && paddr < MEMBASE + MEMSIZE;
}

inline bool in_mrom(uint32_t paddr) {
  return MROMBASE <= paddr && paddr < MROMBASE + MROMSIZE;
}

inline bool in_flash(uint32_t paddr) {
	return FLASHBASE <= paddr && paddr < FLASHBASE + FLASHSIZE;
}

uint32_t pmem_read(uint32_t paddr, int len); 
uint32_t mrom_read_internal(uint32_t addr);
uint32_t flash_read_internal(uint32_t addr); // read 4 bytes
											 
void init_flash_test();
#endif