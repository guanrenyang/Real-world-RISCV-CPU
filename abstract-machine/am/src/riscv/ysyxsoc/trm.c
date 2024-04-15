#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

extern char _heap_start;
int main(const char *args);

extern char _sram_start;
#define SRAM_END ((uintptr_t)&_sram_start + SRAM_SIZE) //_sram_start = 0x0f000000
														
Area heap = RANGE(&_heap_start, SRAM_END); // _heap_start = 0x0f002000
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
	outb(UART_BASE, ch);
}

#define trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))
void halt(int code) {
	trap(code);

	// Should not reach here
	while (1);
}

extern char _erodata, _data, _edata, _bstart, _bend;
void data_seg_copy(){
	uint32_t *src = (uint32_t *) &_erodata;
	uint32_t *dst = (uint32_t *) &_data;

	/* ROM has data at the end of rodata section; copy it. */
	while (dst <(uint32_t *) &_edata)
		*dst++ = *src++;
	
	// /*Zero bss. */
	// for (dst = &_bstart; dst< &_bend; dst++){
	// 	*dst = 0;
	// }
}
void _trm_init() {
	data_seg_copy();
	int ret = main(mainargs);
	halt(ret);
}