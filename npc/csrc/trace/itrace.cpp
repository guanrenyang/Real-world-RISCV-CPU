#include <trace.h>


#ifdef CONFIG_ITRACE
char logbuf[128];
char iringbuf[128][128];

void itrace(uint32_t pc, uint32_t ival, int ilen /*bytes*/){
    char *p = logbuf;
    p += snprintf(p, sizeof(logbuf), FMT_WORD ":", pc);

    int i;
    uint8_t *inst = (uint8_t *)&ival;
    for (i = ilen - 1; i >= 0; i --) {
      p += snprintf(p, 4, " %02x", inst[i]);
    }
    memset(p, ' ', 1);
    p += 1;
}

#else
void itrace(uint32_t pc, uint32_t ival, int ilen){}

#endif


