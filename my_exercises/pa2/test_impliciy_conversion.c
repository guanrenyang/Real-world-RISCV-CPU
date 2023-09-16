#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
void print_binary(uint64_t n) {
    for (int i = 63; i >= 0; i--) {
        printf("%d", (n & (1ULL << i)) ? 1 : 0);
        if (i % 8 == 0 && i != 0) {  // 每8位输出一个空格，方便阅读
            printf(" ");
        }
    }
    printf("\n");
}
int main(){
  int x = -1;
  uint64_t y = (uint64_t) x;

  printf("Value is: %" PRIu64 "\n", y);
  print_binary(y);
  return 0;
}
