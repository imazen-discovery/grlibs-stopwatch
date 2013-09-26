#/*

# Via the magic of C hackery, this program will compile itself when
# run as a shell script (if your system is set up perfectly correctly,
# that is.)

gcc -g -Wall $0 -o ${0%.c} -I../c_tests ../c_tests/util.c ../c_tests/timer.c \
    && \
    ./${0%.c}

exit $?

#*/


#include <stdio.h>
#include <stdlib.h>

#include "timer.h"
#include "util.h"

const int SZ = 2;

static int total = 0;

static void
sumit(double *buffer, int sz) {
    int n, i;
    int sum = 0;
    
    for (i = 0; i < 100000000; i++) {
        for (n = 0; n < sz; n++) {
            sum += (int)buffer[n];
        }/* for */
    }/* for */

    total += sum;
}/* sumit*/


int main() {
    double *buf;
    int n;

    buf = malloc(SZ*sizeof(double));
    check(!!buf, "malloc");

    for (n = 0; n <= 3; n++) {
        timer_start("x", "fs overrun=%d", n);
        sumit(buf, SZ + n);
        timer_done();
    }/* for */

    print_times();

    return 0;
}/* main*/
