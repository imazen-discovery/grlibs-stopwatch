
#include <time.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "util.h"

#define MAXDESC 255
struct Times {
    const char *file;
    char desc[MAXDESC];
    clock_t elapsed;
};


struct Times *times = NULL;
unsigned current = 0;

static clock_t last_time;

void
timer_start(const char *file, const char *descfmt, ...) {
    va_list ap;

    va_start(ap, descfmt);

    times = realloc(times, sizeof(struct Times)* (current + 1));
    check(!!times, "realloc failed!\n");

    last_time = clock();
    times[current].file = file;

    vsnprintf(times[current].desc, MAXDESC, descfmt, ap);

    va_end(ap);
}/* timer_start*/

void
timer_done() {
    clock_t now = clock();
    assert (now >= last_time);

    times[current].elapsed = now - last_time;
    ++current;
}/* timer_done*/


/* Print out the times and also reset the list of times. */
void
print_times() {
    int n = 0;
    double total = 0;

    for (n = 0; n < current; n++) {
        double time = (double)times[n].elapsed / (double)CLOCKS_PER_SEC;
        printf ("%s\t%s\t%f\n", times[n].file, times[n].desc, time*1000.0);
        total += time;
    }/* for */

    printf("(none)\tTotal:\t%f\n", total*1000.0);

    current = 0;
}/* print_times*/
