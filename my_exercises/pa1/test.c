#include <stdio.h>
#include <sys/ucontext.h>

int main() {
#ifdef __USE_MISC
    printf("__USE_MISC is defined\n");
#else
    printf("__USE_MISC is not defined\n");
#endif
    return 0;
}
