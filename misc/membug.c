#/*

# Via the magic of C hackery, this program will compile itself when
# run as a shell script.

# This is a simple C program that reproduces a segfault in
# getImageScale().  The segfault occurs for all interpolation modes
# except GD_BILINEAR_FIXED, GD_BICUBIC_FIXED or GD_NEAREST_NEIGHBOUR.
# In addition, GD_WEIGHTED4 returns a false status for some reason.


# Fetch the test image if not present
[ -f 15.jpg ] || wget http://s3.amazonaws.com/resizer-images/15.jpg

echo "Compiling..."
gcc -g -Wall $0 -o ${0%.c} `pkg-config gdlib --cflags --libs`

echo "Running..."
./${0%.c}

exit $?

#*/

#include "gd.h"

#include <stdio.h>
#include <assert.h> /* quick-and-dirty error checking. */

#define MODE GD_BICUBIC    

int main() {
    /* Declare the image */
    gdImagePtr im, im2;
    FILE *in, *out;
    int stat;

    in = fopen("15.jpg", "r");
    assert(in);

    im = gdImageCreateFromJpeg(in);
    assert(im);

    fclose(in);

    stat = gdImageSetInterpolationMethod(im, MODE);
    assert(stat);

    im2 = gdImageScale(im, 260, 160);
    assert(im2);

    out = fopen("out.jpg", "w");
    assert(out);

    gdImageJpeg(im2, out, 100);

    fclose(out);

    return 0;
}/* main*/
