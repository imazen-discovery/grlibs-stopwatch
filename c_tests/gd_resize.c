
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
save(gdImagePtr img, int pass, const char *template, const char *extra,
     int width) {
    char oname[255];
    FILE *outfile;

    snprintf(oname, sizeof(oname), "%s%s-%d-%d.jpg", template, extra, pass, 
             width);

    outfile = fopen(oname, "w");
    check(!!outfile, "Unable to open '%s' for writing.", oname);

    gdImageJpeg(img, outfile, 100);

    fclose(outfile);
}/* save*/


gdImagePtr
shrink(gdImagePtr im, int pass, int width, const char *ifile, const char *tpl,
       const char *extra, gdInterpolationMethod mode) {
    gdImagePtr dest;
    int height = (int) round( 
        ((double)gdImageSY(im) * (double)width) / (double)gdImageSX(im)
        );

    gdImageSetInterpolationMethod(im, mode);

    timer_start(ifile, "%d%s-%d", width, extra, pass);
    dest = gdImageScale(im, width, height);
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

        im = gdImageCreateFromJpeg(in);
        check(!!im, "Error creating input image object.");

        fclose(in);
    }

    {
        int n;

        for (n = 0; widths[n]; n++) {
            gdImagePtr dest, dest2;
            gdImagePtr dest3;
            int width = widths[n];

            dest = shrink(im, n, width, ifile, ofile_tpl, "", GD_BICUBIC_FIXED2);
            dest2 = shrink(im, n, width, ifile, ofile_tpl,"orig",GD_BICUBIC_FIXED);
            dest3 = shrink(im, n, width, ifile, ofile_tpl, "float", GD_BICUBIC);

            if(gdImageCompare(dest, dest2)) {
                printf("Resulting images differ.\n");
            }/* if*/

            gdImageDestroy(dest);
            gdImageDestroy(dest2);
            gdImageDestroy(dest3);
        }/* for */
    }

    print_times();

    return 0;
}/* main*/
