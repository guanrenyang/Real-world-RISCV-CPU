#include <stdint.h>
#include <dlfcn.h>
#include <macro.h>

enum {DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

#ifdef CONFIG_RVE
#define RISCV_GPR_TYPE uint32_t
#define RISCV_GPR_NUM 16
#define DIFFTEST_REG_SIZE (sizeof(RISCV_GPR_TYPE) * (RISCV_GPR_NUM + 1))
#endif