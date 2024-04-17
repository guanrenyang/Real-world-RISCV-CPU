#include <inttypes.h>

// #define CONFIG_ITRACE y
// #define CONFIG_FTRACE y
// #define CONFIG_DEBUG y
// #define CONFIG_DIFFTEST y
// #define CONFIG_WAVETRACE y
#define CONFIG_TIMER_GETTIMEOFDAY y

#define CONFIG_RVE y

#define FMT_WORD "0x%08" PRIx32

#define RESET_VECTOR 0x20000000

#define MEMBASE 0x0f000000
#define MEMSIZE 0x00002000

#define MROMBASE 0x20000000
#define MROMSIZE 0x1000

#define SERIAL_MMIO 0xa00003f8
#define RTC_MMIO 0xa0000048

