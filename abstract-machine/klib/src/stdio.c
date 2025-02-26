#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static char* itox(int n, char* str) {
  // handle 0 case
  if (n == 0) {
    str[0] = '0';
    str[1] = '\0';
    return str;
  }

  // handle negative case
  bool is_negative = (n < 0);
  unsigned int num;
  if (is_negative) {
    num = -n;
  } else {
    num = n;
  }

  // convert digits
  int i = 0;
  while (num != 0) {
    int digit = num % 16;
    if (digit < 10) {
      str[i++] = digit + '0';
    } else {
      str[i++] = digit - 10 + 'a';
    }
    num = num / 16;
  }

  // add negative sign if needed
  if (is_negative) {
    str[i++] = '-';
  }
  str[i] = '\0';

  // reverse the string in-place
  int start = 0;
  int end = i - 1;
  while (start < end) {
    char temp = str[start];
    str[start] = str[end];
    str[end] = temp;
    start++;
    end--;
  }

  return str;
}
static char* itoa(int n, char* str) {
  // digit parsing
  bool is_negative = (n<0);
  long long_n;
  if (is_negative)
    long_n = -n;
  else
    long_n = n;

  if (long_n==0) {
	str[0] = '0';
	str[1] = '\0';
	return str;
  }

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



int vsprintf(char *out, const char *fmt, va_list ap) {
  int d;
  char *s;
  char c;

  char out_tmp[100];
  bool to_stdout = false;
  if(out==NULL) {
	  out = out_tmp; 
	  to_stdout = true;
  }

  size_t i;
  size_t out_i = 0;
  for ( i = 0; fmt[i] != '\0'; i++) {
    if (fmt[i] != '%') 
      out[out_i++] = fmt[i];
    else {
      switch (fmt[++i]) {
        case 'x':
          d = va_arg(ap, int);
          char str_x[20];
          itox(d, str_x);
          strcpy(out+out_i, str_x);
          out_i += strlen(str_x);
          break;
	      case 'd':
	        d = va_arg(ap, int);
	        char str_d[20];
	        itoa(d, str_d);
	        strcpy(out+out_i, str_d);
	        out_i += strlen(str_d);
	        break;
	      case 's':
	        s = va_arg(ap, char *);
	        strcpy(out+out_i, s);
	        out_i += strlen(s);
	        break;
		  case 'c':
		  	c = va_arg(ap, int);
			out[out_i++] = c;	
			break;
	      case '%':
	        out[out_i++] = '%';
            break;
	      default:
            break;
      }
    }  
  }
  out[out_i] = '\0';
  if(to_stdout) {
	  size_t j;
	  for(j=0; j<out_i; j++)
		  putch(out[j]);
  }

  return (out_i + 1);
}

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);

  int ret = vsprintf(NULL, fmt, ap);

  va_end(ap);

  return ret;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);

  int ret = vsprintf(out, fmt, ap);

  va_end(ap);

  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
