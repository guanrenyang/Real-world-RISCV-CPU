#include <macro.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

void itrace(uint32_t pc, uint32_t ival, int ilen /*bytes*/);
void ftrace(uint32_t inst, uint32_t dnpc, uint32_t pc);