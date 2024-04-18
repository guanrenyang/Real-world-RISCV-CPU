#ifndef YSYXSOC_H__
#define YSYXSOC_H__

#include <klib-macros.h>

#include ISA_H

#define nemu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define AUDIO_ADDR      (DEVICE_BASE + 0x0000200)
#define DISK_ADDR       (DEVICE_BASE + 0x0000300)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
#define AUDIO_SBUF_ADDR (MMIO_BASE   + 0x1200000)

#define UART_BASE 0x10000000
#define UART_SIZE 0x00001000
#define UART_LCR (UART_BASE + 3)     // Line Control Register
#define UART_LSR (UART_BASE + 5)     // Line Status Register
#define UART_DLL (UART_BASE + 0)     // Divisor Latch Low
#define UART_DLM (UART_BASE + 1)     // Divisor Latch High

#define SRAM_BASE 0x0f000000
#define SRAM_SIZE 0x00100000

#define MROM_BASE 0x20000000
#define MROM_SIZE 0x00100000

#endif
