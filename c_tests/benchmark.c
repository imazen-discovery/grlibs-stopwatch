
// BROKEN.  Ignore.

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



static INTMASK *
mk_convmat () {
    INTMASK *m;
    int coeffs[] = {-1, -1, -1, -1, 16,-1, -1, -1, -1};

    m = im_create_imaskv("conv.mat", 3, 3);
    check(!!m, "im_create_imaskv failed.");

    memcpy(m->coeff, coeffs, 3*3*sizeof(int));

    m->scale = 8;

    return m;
}/* mk_convmat*/

int
main (int argc, char **argv) {
    const int NTMPS = 3;
	VipsImage *in, *out;
    VipsImage *tmps[NTMPS];
    INTMASK *mask;
    int stat;
    const char *ifile, *ofile;

    check(argc == 3, "Syntax: %s <input> <output>", argv[0]);
    ifile = argv[1];
    ofile = argv[2];

    timer_start(ifile, "Setup");

    if (im_init_world (argv[0])) error_exit ("unable to start VIPS");

    in = im_open( ifile, "r" );
    if (!in) vips_error_exit( "unable to read %s", ifile );

    stat = im_open_local_array(in, tmps, NTMPS, "tt", "p");
    check(!stat, "Unable to create temps.");

    mask = mk_convmat();

    timer_done();


    timer_start(ifile, "im_extract_area()");
    check(
        !im_extract_area(in, tmps[0], 100, 100, in->Xsize - 200,
                         in->Ysize - 200),
        "extract failed.");
    timer_done();

    timer_start(ifile, "im_affine()");
    check(
        !im_affine(tmps[0], tmps[1], 0.9, 0, 0, 0.9, 0, 0,
                   0, 0, in->Xsize * 0.9, in->Ysize * 0.9),
        "im_affine failed.");
    timer_done();

    timer_start(ifile, "im_conv()");
    check(
        !im_conv (tmps[1], tmps[2], mask),
        "im_conv failed.");
    timer_done();
        
    timer_start(ofile, "writing output");
    out = im_open(ofile, "w");
    check(!!out, "file output failed.");

    im_copy(tmps[2], out);
    timer_done();
    

    timer_start(ofile, "teardown");
    im_close(out);
    im_close(in);
    timer_done();

    print_times();

    return 0;
}/* main */

