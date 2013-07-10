
#define _GNU_SOURCE     /* Get the GNU version of basename(). */
#include <string.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <assert.h>
#include <unistd.h>

#include <vips/vips.h>

#include "timer.h"
#include "util.h"

static void
showstat(const char *filename) {
    VipsImage *im;
    double min, max, avg, deviate;
    char lfn[255];

    printf ("# File: %s ", filename);   /* In case im_open() segfaults. */
    im = im_open (filename, "r");
    check(!!im, "Unable to open file '%s': %s", filename, im_error_buffer());

    printf("Width: %d Height: %d Depth: %d\n", im->Xsize, im->Ysize,im->Bands);

    /* Append image dimensions to filename. */
    snprintf(lfn, sizeof(lfn), "%s (%d, %d, %d)", filename, im->Xsize, 
             im->Ysize, im->Bands);

    timer_start(lfn, "min");
    check( !im_min(im, &min), "im_min() failed: %s", im_error_buffer());
    timer_done();

    timer_start(lfn, "max");
    check( !im_max(im, &max), "im_max() failed: %s", im_error_buffer());
    timer_done();

    timer_start(lfn, "avg");
    check( !im_avg(im, &avg), "im_avg() failed: %s", im_error_buffer());
    timer_done();

    timer_start(lfn, "deviate");
    check( !im_deviate(im, &deviate), "im_deviate() failed: %s",
           im_error_buffer());
    timer_done();

    printf("# min: %f max: %f avg: %f deviate: %f\n", min, max, avg, deviate);
    print_times();

    im_close(im);
}/* showstat*/


int
main (int argc, char **argv) {
    int n;

    timer_start("(none)", "initializing.");
    if (im_init_world (argv[0])) {
        error_exit ("unable to start VIPS");
    }
    timer_done();

    for (n = 1; n < argc; n++) {
        showstat(argv[n]);
    }/* for */
    
    return (0);
}/* main */

