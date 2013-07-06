
/* Simple-ish C program to shrink one or more files and output the
 * time (in milliseconds) it took to perform the operation.
 *
 * Input consists of one or more repititions of the following: the
 * name of the file to shrink followed by one or more integers
 * representing the percentage (<=100) of the old image the new
 * image's size is.
 *
 */

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

#define MAX_SIZES 40
#define MAX_IMAGES 20

/* List of things to resize and number of different sizes. */
struct ResizeItem {
    const char *name;
    unsigned char sizes[MAX_SIZES];
};

struct ResizeItem resizes[MAX_IMAGES];

static void
parseArgs(int argc, char **argv) {
    int item = 0;
    int n;

    for (n = 1; n < argc; item++) {
        int szpos = 0;

        resizes[item].name = argv[n++];
        check( !access(resizes[item].name, R_OK),
               "Unable to access file '%s'", resizes[item].name);

        for (szpos = 0; n < argc; szpos++, n++) {
            int sz = 0;

            check (szpos < MAX_IMAGES, "Too many image files.");
            
            sz = (int)strtol(argv[n], NULL, 10);
            if (sz == 0) break;

            check (sz > 0 && sz <= 100, 
                   "Illegal size range %d (must be between 1 and 100", sz);
            resizes[item].sizes[szpos] = sz;
        }/* for */

        check (szpos > 0, "No sizes given for image '%s'",
               resizes[item].name );
    }/* for */
}/* parseArgs*/


static void
shrink(int slot, VipsImage *im) {
    int n;

    for(n=0; resizes[slot].sizes[n]; n++) {
        int stat;
        VipsImage *result;
        char ofname[255];
        const char *nm = resizes[slot].name;

        int isize = resizes[slot].sizes[n];
        double scale = 100.0 / (double)isize;

        snprintf(ofname, sizeof(ofname), "%d-%s", isize, 
                 basename(nm)); /* GNU basename, not POSIX */

        result = im_open(ofname, "w");
        check(!!result, "Error opening image on %s", ofname);

        timer_start(nm, "%d%%", isize);
        stat = im_shrink(im, result, scale, scale);
        timer_done();
        check(!stat, "Shrink failed: %s", im_error_buffer());
        
        im_close(result);
    }/* for*/
}/* shrink*/


static void
shrinkall() {
    int n = 0;

    for (n = 0; resizes[n].name; n++) {
        VipsImage *im;

        printf ("# Shrinking %s:\n", resizes[n].name);

        im = im_open (resizes[n].name, "r");
        if (!im) error_exit ("unable to open");

        printf("# %d %d %d\n", im->Xsize, im->Ysize,
               im->Bands);

        shrink(n, im);

        im_close(im);
    }/* for */
}/* shrinkall*/


int
main (int argc, char **argv)
{

    timer_start("(none)", "initializing.");
    if (im_init_world (argv[0])) {
        error_exit ("unable to start VIPS");
    }
    timer_done();

    parseArgs(argc, argv);
    shrinkall();
    print_times();
    
    return (0);
}/* main */

