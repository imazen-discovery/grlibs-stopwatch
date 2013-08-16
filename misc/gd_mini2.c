#/*

# Via the magic of C hackery, this program will compile itself when
# run as a shell script (if your system is set up perfectly correctly,
# that is.)

gcc -g -Wall $0 -o ${0%.c} `pkg-config gdlib --cflags --libs`
exit $?

#*/

/* Basic exercise of gdImageScale(). */

#include "gd.h"

#include <stdio.h>
#include <assert.h> /* quick-and-dirty error checking. */


int main() {
    /* Declare the image */
    gdImagePtr im, im2;
    FILE *in, *out;

    in = fopen("../data/pic1.jpg", "r");
    assert(in);

    im = gdImageCreateFromJpeg(in);
    assert(im);

    fclose(in);

    im2 = gdImageScale(im, 160, 160);
    assert(im2);

    out = fopen("mini2-out.jpg", "w");
    assert(out);

    gdImageJpeg(im2, out, 100);

    fclose(out);

    return 0;
}/* main*/
