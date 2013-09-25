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

typedef struct {
	double *weights;
    int nweights;
} Entry;

typedef struct {
    int width, height;
    int **data;
} Img;

static Entry *
GetWeights(int width, int winsize) {
    Entry *result;
    int n, i;

    result = malloc(width * sizeof(Entry));
    check(!!result, "malloc failed");

    for (n = 0; n < width; n++) {
        result[n].weights = malloc(winsize * sizeof(double));
        check(!!result[n].weights, "malloc failed");

        for (i = 0; i < winsize; i++) {
            result[n].weights[i] = (double)i / (double) n;
        }/* for */
    }/* for */

    return result;
}/* GetWeights*/

static Img *
GetImg(int width, int height) {
    Img *result;
    int **data;
    int y, x;

    data = malloc(height * sizeof(int *));
    check(!!data, "malloc");

    for (y = 0; y < height; y++) {
        data[y] = malloc(width * sizeof(int));
        check(!!data[y], "malloc");

        for (x = 0; x < width; x++) {
            data[y][x] = (x+y) | ((x + y) << 16);
        }/* for */
    }/* for */

    result = malloc(sizeof(Img));
    check(!!result, "malloc");
    
    result->width = width;
    result->height = height;
    result->data = data;

    return result;
}/* GetImg*/

static void
FakeShrink(Img *src, Img *dest, Entry *weights) {
    int x, y, w;

    check(src->height == dest->height, "heights");
    check(src->width > dest->width, "widths");

    for (y = 0; y < dest->height; y++) {
        for (x = 0; x < dest->width; x++) {
            int result = 0;
            for (w = 0; w < weights[x].nweights; w++) { // <--- HERE
                result += src->data[y][w+x] * weights[x].weights[w];
            }/* for */
            dest->data[y][x] = result;
        }/* for */
    }/* for */
}/* FakeShrink*/



int main() {
    const int SRCW = 6400, SRCH = 4266;
    const int DESTW = 4160, DESTH = SRCH;//1386;
    const int WIN = 5;

    Entry *weights;
    Img *src, *dest;

    timer_start("x", "setup");
    src = GetImg(SRCW, SRCH);
    dest = GetImg(DESTW, DESTH);
    weights = GetWeights(DESTW, WIN);
    timer_done();

    timer_start("x", "fake shrink");
    FakeShrink(src, dest, weights);
    timer_done();

    print_times();

    return 0;
}/* main*/
