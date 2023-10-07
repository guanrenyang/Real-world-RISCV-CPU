#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t sum;

  for (sum = 0; s[sum]!='\0'; sum++) {}

  return sum;
}

char *strcpy(char *dst, const char *src) {
  size_t i;

  for (i = 0; src[i] != '\0'; i++)
    dst[i] = src[i];
  dst[i] = '\0';

  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;

  for (i = 0; i < n && src[i] != '\0'; i++)
    dst[i] = src[i];
  for ( ; i < n; i++)
    dst[i] = '\0';
  
  return dst;
}

char *strcat(char *dst, const char *src) {
  size_t dst_len = strlen(dst);
  size_t i;

  for (i = 0 ; src[i] != '\0' ; i++)
      dst[dst_len + i] = src[i];
  dst[dst_len + i] = '\0';

  return dst;

}

int strcmp(const char *s1, const char *s2) {
  
  while (*s1 && (*s1 == *s2)) {
    s1++;
    s2++;
  }
  return *(unsigned char *)s1 - *(unsigned char *)s2;  
}

int strncmp(const char *s1, const char *s2, size_t n) {
  size_t i = 0;
  while (i < n && s1[i] && s1[i] == s2[i]) {
    i++;
  }
  if (i < n) {
    return ((unsigned char)s1[i] - (unsigned char)s2[i]);
  }
  return 0;
}

void *memset(void *s, int c, size_t n) {
  unsigned char* p = s;
  while (n--) {
    *p++ = (unsigned char)c;
  }
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  panic("Not implemented");
}

void *memcpy(void *out, const void *in, size_t n) {
  panic("Not implemented");
}

int memcmp(const void *s1, const void *s2, size_t n) {
  const unsigned char *p1 = s1;
  const unsigned char *p2 = s2;
  
  size_t i;
  for (i = 0; i < n; ++i) {
    if (p1[i] != p2[i]) {
      return p1[i] - p2[i];
    }
  }
  return 0;
}

#endif
