#ifndef YSYXSOC_H__
#define YSYXSOC_H__

#include <klib-macros.h>

#include ISA_H

#define nemu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

#define UART_BASE 0x10000000
#define UART_SIZE 0x00001000

#define SRAM_BASE 0x0f000000
#define SRAM_SIZE 0x0f002000

#define MROM_BASE 0x20000000
#define MROM_SIZE 0x00001000

#endif
