
#include <time.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "util.h"

#define UCLOCK CLOCK_MONOTONIC

#define MAXDESC 255
struct Times {
    const char *file;
    char desc[MAXDESC];
    double elapsed;
};


struct Times *times = NULL;
unsigned current = 0;

static struct timespec last_time;

static inline double floattime(struct timespec now) {
    return (double)now.tv_sec + (double)now.tv_nsec/1000000000.0;
}

void
timer_start(const char *file, const char *descfmt, ...) {
    va_list ap;

    va_start(ap, descfmt);

    times = realloc(times, sizeof(struct Times)* (current + 1));
    check(!!times, "realloc failed!\n");

    check(!clock_gettime(UCLOCK, &last_time), "clock_gettime() failed.");
    times[current].file = file;

    vsnprintf(times[current].desc, MAXDESC, descfmt, ap);

    va_end(ap);
}/* timer_start*/

void
timer_done() {
    struct timespec now;

    check(!clock_gettime(UCLOCK, &now), "clock_gettime() failed.");

    times[current].elapsed = floattime(now) - floattime(last_time);
    ++current;
}/* timer_done*/


/* Print out the times and also reset the list of times. */
void
print_times() {
    int n = 0;
    double total = 0;

    for (n = 0; n < current; n++) {
        printf ("%s\t%s\t%f\n", times[n].file, times[n].desc,
                times[n].elapsed*1000.0);
        total += times[n].elapsed;
    }/* for */

    printf("(none)\tTotal:\t%f\n", total*1000.0);

    current = 0;
}/* print_times*/
