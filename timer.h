
#ifndef __TIMER_H
#define __TIMER_H

void timer_start(const char *file, const char *desc, ...);
void timer_done(void);
void print_times(void);

#endif
