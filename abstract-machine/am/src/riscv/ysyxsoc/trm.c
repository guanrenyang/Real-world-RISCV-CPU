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

void _trm_init() {
	int ret = main(mainargs);
	halt(ret);
}