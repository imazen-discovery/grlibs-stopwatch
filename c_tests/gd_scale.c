
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <gd.h>

#include "util.h"
#include "timer.h"

#define WIDTH_START 3   /* First width on the command line. */

void
getwidths(int argc, char *argv[], int widths[], size_t widthsSize) {
    int n;
    size_t numw = widthsSize/sizeof(int) - 1;

    for (n = 0; n < numw && n + WIDTH_START < argc; n++) {
        const char *arg = argv[n+WIDTH_START];
        int sz;

        sz = atoi(arg);
        check(sz > 0, "Invalid width argument: '%s'", arg);
        
        widths[n] = sz;
    }/* for */

    widths[n] = 0;  /* zero-terminate. */
}/* getwidths*/


void
save(gdImagePtr img, int pass, const char *template, const char *extra,
     int width) {
    char oname[255];
    FILE *outfile;

    snprintf(oname, sizeof(oname), "%s%s-%d-%d.png", template, extra, pass, 
             width);

    outfile = fopen(oname, "w");
    check(!!outfile, "Unable to open '%s' for writing.", oname);

    gdImagePng(img, outfile);

    fclose(outfile);
}/* save*/


#define CLASSIC_RESIZE_RS -1
#define CLASSIC_RESIZE    -2

gdImagePtr
shrink(gdImagePtr im, int pass, int width, const char *ifile, const char *tpl,
       const char *extra, int mode) {
    gdImagePtr dest;
    int height = (int) round( 
        ((double)gdImageSY(im) * (double)width) / (double)gdImageSX(im)
        );

    if (mode >= 0) {
        gdImageSetInterpolationMethod(im, mode);
    }

    timer_start(ifile, "%d%s-%d", width, extra, pass);
    if (mode == CLASSIC_RESIZE_RS) {
        dest = gdImageCreateTrueColor(width, height);
        gdImageCopyResampled(dest, im, 0, 0, 0, 0,
                             width, height,
                             im->sx, im->sy);
    } else if (mode == CLASSIC_RESIZE) {
        dest = gdImageCreateTrueColor(width, height);
        gdImageCopyResized(dest, im, 0, 0, 0, 0,
                           width, height,
                           im->sx, im->sy);
    } else {
        dest = gdImageScale(im, width, height);
    }/* if .. else*/
    timer_done();

    check(!!dest, "Scale op failed.");

    save(dest, pass, tpl, extra, width);

    return dest;
}/* shrink*/


int
main(int argc, char *argv[]) {
    /* Declare the image */
    gdImagePtr im;
    char *ifile, *ofile_tpl;
    int widths[100];
    
    check(argc >= 4, "usage: gd_resize <input> <output> <width> ...");

    ifile = argv[1];
    ofile_tpl = argv[2];

    getwidths(argc, argv, widths, sizeof(widths));

    /* Read in the input file. */
    {
        FILE *in = fopen(ifile, "r");
        check(!!in, "Error opening '%s'", ifile);

        timer_start(ifile, "loading...");
        im = gdImageCreateFromPng(in);
        check(!!im, "Error creating input image object.");
        timer_done();

        fclose(in);
    }

    {
        int n;

        for (n = 0; widths[n]; n++) {
            gdImagePtr dest, dest3, dest4, dest5;
            int width = widths[n];

            dest = shrink(im, n, width, ifile, ofile_tpl, "", GD_BICUBIC_FIXED);
            dest3 = shrink(im, n, width, ifile, ofile_tpl, "float", GD_BICUBIC);
            dest4 = shrink(im, n, width, ifile, ofile_tpl, "classic-resampled",
                           CLASSIC_RESIZE_RS);
            dest5 = shrink(im, n, width, ifile, ofile_tpl, "classic-resize",
                           CLASSIC_RESIZE);

            gdImageDestroy(dest);
            gdImageDestroy(dest3);
            gdImageDestroy(dest4);
            gdImageDestroy(dest5);
        }/* for */
    }

    print_times();

    return 0;
}/* main*/
