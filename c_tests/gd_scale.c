
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#include <gd.h>

#include "util.h"
#include "timer.h"

enum FType {UNKNOWN, PNG, JPG, GIF, TIFF};
struct {
    enum FType id;
    const char *ext;
} Types[] = {
    {PNG,   ".png"},
    {JPG,   ".jpg"},
    {JPG,   ".jpeg"},
    {GIF,   ".gif"},
    {TIFF,  ".tiff"},
    
    {UNKNOWN, NULL}
};


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


enum FType
ftype(const char *filename) {
    size_t len = strlen(filename);
    int n;

    check(len > 5, "Invalid filename '%s' (too short).", filename);

    for (n = 0; Types[n].ext; n++) {
        const char *ext = &filename[len - strlen(Types[n].ext)];

        if (strcasecmp(ext, Types[n].ext) == 0) {
            return Types[n].id;
        }/* if */
    }/* for */

    return UNKNOWN;
}/* ftype*/


void
save(gdImagePtr im, int pass, const char *template, const char *interp,
     int width, enum FType type) {
    char oname[255];
    FILE *out;
    const char *ext;
    int n;

    for (n = 0, ext = NULL; Types[n].ext; n++) {
        if (Types[n].id == type) {
            ext = Types[n].ext;
            break;
        }/* if */
    }/* for */
        
    snprintf(oname, sizeof(oname), "%s-%s-%d-%d%s", template, interp, pass, 
             width, ext);

    out = fopen(oname, "wb");
    check(!!out, "Unable to open '%s' for writing.", oname);

    switch(type) {
    case PNG:   gdImagePng(im, out);        break;
    case JPG:   gdImageJpeg(im, out, 100);  break;
    case GIF:   gdImageGif(im, out);        break;
    case TIFF:  gdImageTiff(im, out);       break;
    default:
        check(0, "invalid type: %d", type);
    }/* switch*/

    fclose(out);
}/* save*/


gdImagePtr
load(const char *filename, enum FType type) {
    gdImagePtr im;
    FILE *in;

    in = fopen(filename, "r");
    check(!!in, "Error opening '%s'", filename);

    timer_start(filename, "loading...");

    switch(type) {
    case PNG:   im = gdImageCreateFromPng(in);      break;
    case JPG:   im = gdImageCreateFromJpeg(in);     break;
    case GIF:   im = gdImageCreateFromGif(in);      break;
    case TIFF:  im = gdImageCreateFromTiff(in);     break;

    default:    im = NULL;
    }/* switch*/
        
    check(!!im, "Error creating input image object.");
    timer_done();

    fclose(in);

    return im;
}/* load*/

#define CLASSIC_RESIZE_RS -1
#define CLASSIC_RESIZE    -2

gdImagePtr
shrink(gdImagePtr im, int pass, int width, const char *ifile, const char *tpl,
       enum FType type, const char *extra, int mode) {
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

    save(dest, pass, tpl, extra, width, type);

    return dest;
}/* shrink*/


int
main(int argc, char *argv[]) {
    /* Declare the image */
    gdImagePtr im;
    char *ifile, *ofile_tpl;
    int widths[100], n;
    enum FType type;
    
    check(argc >= 4, "usage: gd_resize <input> <output> <width> ...");

    ifile = argv[1];
    ofile_tpl = argv[2];
    getwidths(argc, argv, widths, sizeof(widths));

    type = ftype(ifile);

    im = load(ifile, type);

    for (n = 0; widths[n]; n++) {
        gdImagePtr dest, dest3, dest4, dest5;
        int width = widths[n];

        dest  = shrink(im, n, width, ifile, ofile_tpl, type, 
                       "fixed", GD_BICUBIC_FIXED);
        dest3 = shrink(im, n, width, ifile, ofile_tpl, type,
                       "float", GD_BICUBIC);
        dest4 = shrink(im, n, width, ifile, ofile_tpl, type,
                       "classic-resampled", CLASSIC_RESIZE_RS);
        dest5 = shrink(im, n, width, ifile, ofile_tpl, type,
                       "classic-resize", CLASSIC_RESIZE);

        gdImageDestroy(dest);
        gdImageDestroy(dest3);
        gdImageDestroy(dest4);
        gdImageDestroy(dest5);
    }/* for */

    print_times();

    return 0;
}/* main*/
