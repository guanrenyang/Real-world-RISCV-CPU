#include <am.h>
#include <ysyxsoc.h>
void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uint32_t lo = inl(RTC_ADDR);
  uint32_t hi = inl(RTC_ADDR + 4);
  // uptime->us = lo | ((uint64_t)hi << 32);
  uint64_t hard_time = lo | ((uint64_t)hi << 32);
  uptime->us = (uint64_t) (hard_time * 4 + 50); 
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
