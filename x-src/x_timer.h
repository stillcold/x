#ifndef _TIMER_H
#define _TIMER_H

#include <stdint.h>

void x_timer_init();
void x_timer_exit();
void x_timer_update();
uint32_t x_timer_timeout(uint32_t expire);
uint64_t x_timer_now();
uint64_t x_timer_monotonic();
time_t x_timer_monotonicsec();

#endif


