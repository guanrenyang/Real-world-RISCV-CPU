#include <macro.h>
#include <cstddef>

#ifdef CONFIG_TIMER_GETTIMEOFDAY
#include <sys/time.h>
#else
#include <time.h>
#endif

#ifndef CONFIG_TIMER_GETTIMEOFDAY
    static_assert(CLOCKS_PER_SEC == 1000000, "CLOCKS_PER_SEC != 1000000"));
    static_assert(sizeof(clock_t) == 8, "sizeof(clock_t) != 8"));
#endif

static uint64_t boot_time = 0;

static uint64_t get_time_internal() {
#if defined(CONFIG_TIMER_GETTIMEOFDAY)
  struct timeval now;
  gettimeofday(&now, NULL);
  uint64_t us = now.tv_sec * 1000000 + now.tv_usec;
#else
  struct timespec now;
  clock_gettime(CLOCK_MONOTONIC_COARSE, &now);
  uint64_t us = now.tv_sec * 1000000 + now.tv_nsec / 1000;
#endif
  return us;
}

uint64_t get_time() {
  if (boot_time == 0) boot_time = get_time_internal();
  uint64_t now = get_time_internal();
  return now - boot_time;
}

