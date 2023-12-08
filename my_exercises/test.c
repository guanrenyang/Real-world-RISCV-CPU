#include <stdio.h>

int globalVar = 10;

void modifyGlobalVar(int globalVar) {
    globalVar = 20;
}

int main() {
    printf("Before: %d\n", globalVar);
    modifyGlobalVar(globalVar);
    printf("After: %d\n", globalVar);
    return 0;
}
  
