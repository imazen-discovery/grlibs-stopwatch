
/* We use assert for error checking, so it shouldn't be disabled. */
#ifdef NDEBUG
#undef NDEBUG
#endif


#include <stdio.h>
#include <stdlib.h>
#include <math.h>

//#include <google/profiler.h>

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
save(gdImagePtr img, const char *template, int width) {
    char oname[255];
    FILE *outfile;

    snprintf(oname, sizeof(oname), "%s-%d.jpg", template, width);

    outfile = fopen(oname, "w");
    check(!!outfile, "Unable to open '%s' for writing.", oname);

    gdImageJpeg(img, outfile, 100);

    fclose(outfile);
}/* save*/


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

        im = gdImageCreateFromJpeg(in);
        check(!!im, "Error creating input image object.");

        fclose(in);
    }

    gdImageSetInterpolationMethod(im, GD_BICUBIC); //GD_BICUBIC_FIXED);

    {
        int n;

        for (n = 0; widths[n]; n++) {
            gdImagePtr dest;
            int width = widths[n];
            int height = (int) round( 
                ((double)gdImageSY(im) * (double)width) / (double)gdImageSX(im)
                );

            timer_start(ifile, "%d", width);
            dest = gdImageScale(im, width, height);
            timer_done();

            check(!!dest, "Scale op failed.");

            save(dest, ofile_tpl, width);
            
            gdImageDestroy(dest);
        }/* for */
    }

    print_times();

    return 0;
}/* main*/
