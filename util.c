
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

void
check(int cond, const char *fmt, ...) {
    va_list ap;
    
    va_start(ap, fmt);

    if (!cond) {
        printf("Fatal error: ");
        vprintf (fmt, ap);
        printf("\n");
        exit(1);
    }/* if */

    va_end(ap);
}/* check*/

