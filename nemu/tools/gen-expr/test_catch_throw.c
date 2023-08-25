#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <stdint.h>

void handle_divide_by_zero(int sig) {
    if (sig == SIGFPE) {
        printf("Error: Division by zero!\n");
        exit(1); // Terminate the program and return 1
    }
}

int main() {

    uint32_t tmp = 1/0;
    printf("%d\n", tmp);

    return 0;
}
