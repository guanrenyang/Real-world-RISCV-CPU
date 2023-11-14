#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <macro.h>

uint8_t* guest_to_host(uint32_t paddr);
uint32_t paddr_read(uint32_t paddr, int len); 

// extern "C" void pmem_read(int raddr, int rdata);
// void pmem_write(int waddr, int wdata, char wmask);