#ifndef __UTILS_H__
#define __UTILS_H__
#include <macro.h>

uint64_t get_time();

#define log_write(...) do { extern FILE* log_fp; fprintf(log_fp, __VA_ARGS__); fflush(log_fp);} while (0)
#endif