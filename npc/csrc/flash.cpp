#include <utils.h>
#include <npc.h>
#include <paddr.h>
static uint8_t flash[FLASHSIZE] __attribute((aligned(4096))) = {};

extern char *img_file;

void init_flash_test(){
	for(size_t i = 0; i < FLASHSIZE * sizeof(uint8_t) / sizeof(uint32_t); i+=sizeof(uint32_t)){
		*(uint32_t*)(flash+i) = i;
	}
}

uint8_t* guest_to_host_flash(uint32_t paddr) { return  flash + paddr - FLASHBASE; }

uint32_t host_read(void *addr, int len);

uint32_t flash_read_internal(uint32_t addr) { // read 4 bytes
	addr += 0x30000000L; // A trick to match the bahavior of ysyxSoC/perip/spi/rtl/spi_top_apb.v, which mask the high 8 bit of addr to 0.
	assert(guest_to_host_flash(addr) < (flash + FLASHSIZE));
	return host_read(guest_to_host_flash(addr), 4);
}
extern "C" void flash_read(uint32_t addr, uint32_t *data) { 
	(*data) = flash_read_internal(addr);
}