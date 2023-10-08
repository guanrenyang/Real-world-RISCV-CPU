#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
char* itoa(int n, char* str) {
  // digit parsing
  bool is_negative = (n<0);
  long long_n;
  if (is_negative)
    long_n = -n;
  else
    long_n = n;

  size_t i = 0;
  while (long_n!=0) {
    str[i++] = long_n%10 + '0';
    long_n = long_n/10;
  }
  if (is_negative)
    str[i++] = '-';
  str[i] = '\0';

  // in-place reversion
  char swap_tmp;
  size_t num_bit = i;
  for ( i = 0; i < num_bit / 2; i++) {
    swap_tmp = str[i];
    str[i] = str[num_bit-1-i];
    str[num_bit-1-i] = swap_tmp;
  }
  
  return str; 
}
int main(){
    char *out = malloc(100*sizeof(char));
    int a = 100;
    itoa(a, out);
    printf("result: %s", out);
    return 0; 
}