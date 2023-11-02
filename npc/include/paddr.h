#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <inttypes.h>

#include <macro.h>

uint8_t* guest_to_host(uint32_t paddr);
uint32_t paddr_read(uint32_t paddr, int len); 