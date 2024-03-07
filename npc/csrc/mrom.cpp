#include <utils.h>
#include <npc.h>
#include <paddr.h>
static uint8_t mrom[MROMSIZE] __attribute((aligned(4096))) = {};

extern char *img_file;

uint8_t* guest_to_host_mrom(uint32_t paddr) { return  mrom + paddr - MROMBASE; }

uint32_t host_read(void *addr, int len);

extern "C" void mrom_read(uint32_t addr, uint32_t *data) { 
	assert(guest_to_host_mrom(addr) < (mrom + MROMSIZE));
	(*data) = host_read(guest_to_host_mrom(addr), 4);
}