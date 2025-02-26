#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

FILE *log_fp = NULL;

void init_log(const char *log_file) {
	log_fp = stdout;
	if (log_file != NULL) {
		FILE *fp = fopen(log_file, "w");
		assert(fp != NULL);
		log_fp = fp;
	}
	printf("Log is written to %s", log_file ? log_file : "stdout");
}