#include <inttypes.h>

#define CONFIG_ITRACE y

#define FMT_WORD "0x%08" PRIx32

#define RESET_VECTOR 0x80000000
#define MEMBASE 0x80000000
#define MEMSIZE 0x8000000