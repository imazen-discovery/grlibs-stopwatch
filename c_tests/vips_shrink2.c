
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
#include <math.h>

#include <vips/vips.h>

#include "timer.h"
#include "util.h"

/* Adapted from vipsthumbnail.
 */

static int thumbnail_width = 128;
static int thumbnail_height = 128;
static char *interpolator = "bicubic";
static char *export_profile = NULL;
static char *import_profile = NULL;
static char *convolution_mask = "mild";
static gboolean delete_profile = FALSE;

/* Calculate the shrink factors. 
 *
 * We shrink in two stages: first, a shrink with a block average. This can
 * only accurately shrink by integer factors. We then do a second shrink with
 * a supplied interpolator to get the exact size we want.
 */
static int
calculate_shrink( int width, int height, double *residual )
{
	/* Calculate the horizontal and vertical shrink we'd need to fit the
	 * image to the bounding box, and pick the biggest.
	 */
	double horizontal = (double) width / thumbnail_width;
	double vertical = (double) height / thumbnail_height;
	double factor = VIPS_MAX( horizontal, vertical ); 

	/* If the shrink factor is <= 1.0, we need to zoom rather than shrink.
	 * Just set the factor to 1 in this case.
	 */
	double factor2 = factor < 1.0 ? 1.0 : factor;

	/* Int component of shrink.
	 */
	int shrink = floor( factor2 );

	if( residual ) {
		/* Width after int shrink.
		 */
		int iwidth = width / shrink;

		/* Therefore residual scale factor is.
		 */
		*residual = (width / factor) / iwidth; 
	}

	return( shrink );
}

/* Find the best jpeg preload shrink.
 */
static int
thumbnail_find_jpegshrink( VipsImage *im )
{
	int shrink = calculate_shrink( im->Xsize, im->Ysize, NULL );

	if( shrink >= 8 )
		return( 8 );
	else if( shrink >= 4 )
		return( 4 );
	else if( shrink >= 2 )
		return( 2 );
	else 
		return( 1 );
}

#define THUMBNAIL "jpeg-thumbnail-data"

/* Try to read an embedded thumbnail. 
 */
static VipsImage *
thumbnail_get_thumbnail( VipsImage *im )
{
	void *ptr;
	size_t size;
	VipsImage *thumb;
	double residual;
	int jpegshrink;

	if( !vips_image_get_typeof( im, THUMBNAIL ) ||
		vips_image_get_blob( im, THUMBNAIL, &ptr, &size ) ||
		vips_jpegload_buffer( ptr, size, &thumb, NULL ) ) {
		vips_info( "vipsthumbnail", "no jpeg thumbnail" ); 
		return( NULL ); 
	}

	calculate_shrink( thumb->Xsize, thumb->Ysize, &residual );
	if( residual > 1.0 ) { 
		vips_info( "vipsthumbnail", "jpeg thumbnail too small" ); 
		g_object_unref( thumb ); 
		return( NULL ); 
	}

	/* Reload with the correct downshrink.
	 */
	jpegshrink = thumbnail_find_jpegshrink( thumb );
	vips_info( "vipsthumbnail", 
		"loading jpeg thumbnail with factor %d pre-shrink", 
		jpegshrink );
	g_object_unref( thumb );
	if( vips_jpegload_buffer( ptr, size, &thumb, 
		"shrink", jpegshrink,
		NULL ) ) {
		vips_info( "vipsthumbnail", "jpeg thumbnail reload failed" ); 
		return( NULL ); 
	}

	vips_info( "vipsthumbnail", "using %dx%d jpeg thumbnail", 
		thumb->Xsize, thumb->Ysize ); 

	return( thumb );
}

/* Open an image, returning the best version of that image for thumbnailing. 
 *
 * jpegs can have embedded thumbnails ... use that if it's large enough.
 *
 * libjpeg supports fast shrink-on-read, so if we have a JPEG, we can ask 
 * VIPS to load a lower resolution version.
 */
static VipsImage *
thumbnail_open( VipsObject *thumbnail, const char *filename )
{
	const char *loader;
	VipsImage *im;

	vips_info( "vipsthumbnail", "thumbnailing %s", filename );

	if( !(loader = vips_foreign_find_load( filename )) )
		return( NULL );

	vips_info( "vipsthumbnail", "selected loader is %s", loader ); 

	if( strcmp( loader, "VipsForeignLoadJpegFile" ) == 0 ) {
		VipsImage *thumb;

		/* This will just read in the header and is quick.
		 */
		if( !(im = vips_image_new_from_file( filename )) )
			return( NULL );

		/* Try to read an embedded thumbnail. If we find one, use that
		 * instead.
		 */
		if( (thumb = thumbnail_get_thumbnail( im )) ) { 
			/* @thumb has not been fully decoded yet ... 
			 * we must not close @im until we're done with @thumb.
			 */
			vips_object_local( VIPS_OBJECT( thumb ), im );

			im = thumb;
		}
		else {
			int jpegshrink;

			vips_info( "vipsthumbnail", 
				"processing main jpeg image" );

			jpegshrink = thumbnail_find_jpegshrink( im );

			g_object_unref( im );

			vips_info( "vipsthumbnail", 
				"loading jpeg with factor %d pre-shrink", 
				jpegshrink ); 

			if( vips_foreign_load( filename, &im,
				"access", VIPS_ACCESS_SEQUENTIAL,
				"shrink", jpegshrink,
				NULL ) )
				return( NULL );
		}
	}
	else {
		/* All other formats.
		 */
		if( vips_foreign_load( filename, &im,
			"access", VIPS_ACCESS_SEQUENTIAL,
			NULL ) )
			return( NULL );
	}

	vips_object_local( thumbnail, im );

	return( im ); 
}

static VipsImage *
thumbnail_shrink( VipsObject *thumbnail, VipsImage *in, 
	VipsInterpolate *interp, INTMASK *sharpen )
{
	VipsImage **t = (VipsImage **) vips_object_local_array( thumbnail, 10 );

	int shrink; 
	double residual; 
	int tile_width;
	int tile_height;
	int nlines;

	/* Unpack the two coded formats we support.
	 */
	if( in->Coding == VIPS_CODING_LABQ ) {
		vips_info( "vipsthumbnail", "unpacking LAB to RGB" );

		if( vips_colourspace( in, &t[0], 
			VIPS_INTERPRETATION_sRGB, NULL ) ) 
			return( NULL ); 

		in = t[0];
	}
	else if( in->Coding == IM_CODING_RAD ) {
		vips_info( "vipsthumbnail", "unpacking Rad to float" );

		/* rad is scrgb.
		 */
		if( vips_rad2float( in, &t[1], NULL ) ||
			vips_colourspace( t[1], &t[2], 
				VIPS_INTERPRETATION_sRGB, NULL ) ) 
			return( NULL );

		in = t[2];
	}

	shrink = calculate_shrink( in->Xsize, in->Ysize, &residual );

	vips_info( "vipsthumbnail", "integer shrink by %d", shrink );

	if( vips_shrink( in, &t[3], shrink, shrink, NULL ) ) 
		return( NULL );
	in = t[3];

	/* We want to make sure we read the image sequentially.
	 * However, the convolution we may be doing later will force us 
	 * into SMALLTILE or maybe FATSTRIP mode and that will break
	 * sequentiality.
	 *
	 * So ... read into a cache where tiles are scanlines, and make sure
	 * we keep enough scanlines to be able to serve a line of tiles.
	 *
	 * We use a threaded tilecache to avoid a deadlock: suppose thread1,
	 * evaluating the top block of the output, is delayed, and thread2, 
	 * evaluating the second block, gets here first (this can happen on 
	 * a heavily-loaded system). 
	 *
	 * With an unthreaded tilecache (as we had before), thread2 will get
	 * the cache lock and start evaling the second block of the shrink. 
	 * When it reaches the png reader it will stall until the first block 
	 * has been used ... but it never will, since thread1 will block on 
	 * this cache lock. 
	 */
	vips_get_tile_size( in, 
		&tile_width, &tile_height, &nlines );
	if( vips_tilecache( in, &t[4], 
		"tile_width", in->Xsize,
		"tile_height", 10,
		"max_tiles", (nlines * 2) / 10,
		"access", VIPS_ACCESS_SEQUENTIAL,
		"threaded", TRUE, 
		NULL ) ||
		vips_affine( t[4], &t[5], residual, 0, 0, residual, NULL, 
			"interpolate", interp,
			NULL ) )  
		return( NULL );
	in = t[5];

	vips_info( "vipsthumbnail", "residual scale by %g", residual );
	vips_info( "vipsthumbnail", "%s interpolation", 
		VIPS_OBJECT_GET_CLASS( interp )->nickname );

	/* If we are upsampling, don't sharpen, since nearest looks dumb
	 * sharpened.
	 */
	if( shrink >= 1 && 
		residual <= 1.0 && 
		sharpen ) { 
		vips_info( "vipsthumbnail", "sharpening thumbnail" );
		t[6] = vips_image_new();
		if( im_conv( in, t[6], sharpen ) ) 
			return( NULL );
		in = t[6];
	}

	/* Colour management: we can transform the image if we have an output
	 * profile and an input profile. The input profile can be in the
	 * image, or if there is no profile there, supplied by the user.
	 */
	if( export_profile &&
		(vips_image_get_typeof( in, VIPS_META_ICC_NAME ) || 
		 import_profile) ) {
		if( vips_image_get_typeof( in, VIPS_META_ICC_NAME ) )
			vips_info( "vipsthumbnail", 
				"importing with embedded profile" );
		else
			vips_info( "vipsthumbnail", 
				"importing with profile %s", import_profile );

		vips_info( "vipsthumbnail", 
			"exporting with profile %s", export_profile );

		if( vips_icc_transform( in, &t[7], export_profile,
			"input_profile", import_profile,
			"embedded", TRUE,
			NULL ) )  
			return( NULL );

		in = t[7];
	}

	if( delete_profile &&
		vips_image_get_typeof( in, VIPS_META_ICC_NAME ) ) {
		vips_info( "vipsthumbnail", 
			"deleting profile from output image" );
		if( vips_image_remove( in, VIPS_META_ICC_NAME ) ) 
			return( NULL );
	}

	return( in );
}

static VipsInterpolate *
thumbnail_interpolator( VipsObject *thumbnail, VipsImage *in )
{
	double residual;
	VipsInterpolate *interp;

	calculate_shrink( in->Xsize, in->Ysize, &residual );

	/* For images smaller than the thumbnail, we upscale with nearest
	 * neighbor. Otherwise we makes thumbnails that look fuzzy and awful.
	 */
	if( !(interp = VIPS_INTERPOLATE( vips_object_new_from_string( 
		g_type_class_ref( VIPS_TYPE_INTERPOLATE ), 
		residual > 1.0 ? "nearest" : interpolator ) )) )
		return( NULL );

	vips_object_local( thumbnail, interp );

	return( interp );
}

/* Some interpolators look a little soft, so we have an optional sharpening
 * stage.
 */
static INTMASK *
thumbnail_sharpen( void )
{
	static INTMASK *mask = NULL;

	if( !mask )  {
		if( strcmp( convolution_mask, "none" ) == 0 ) 
			mask = NULL; 
		else if( strcmp( convolution_mask, "mild" ) == 0 ) {
			mask = im_create_imaskv( "sharpen.con", 3, 3,
				-1, -1, -1,
				-1, 32, -1,
				-1, -1, -1 );
			mask->scale = 24;
		}
		else
			if( !(mask = im_read_imask( convolution_mask )) )
				vips_error_exit( "unable to load sharpen" );
	}

	return( mask );
}

static int
shrink(VipsObject *thumbnail, const char *in_name, const char *out_name)
{
	VipsImage *in;
	VipsInterpolate *interp;
	INTMASK *sharpen;
	VipsImage *thumb;

	printf( "shrink: in = %s, out = %s\n", in_name, out_name); 

	if( !(in = thumbnail_open( thumbnail, in_name )) )
		return( -1 );
	if( !(interp = thumbnail_interpolator( thumbnail, in )) )
		return( -1 );
	sharpen = thumbnail_sharpen();
	if( !(thumb = thumbnail_shrink( thumbnail, in, interp, sharpen )) )
		return( -1 );
	if( vips_image_write_to_file( thumb, out_name ) ) 
		return( -1 );

	return( 0 );
}

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
shrinkall() {
    int i, j;
    VipsImage *im;
    char ofname[255];
	int width, height; 

    for (i = 0; resizes[i].name; i++) {
        printf ("# Shrinking %s:\n", resizes[i].name);

		im = vips_image_new_from_file (resizes[i].name);
		if (!im) vips_error_exit ("unable to open");
		width = im->Xsize;
		height = im->Ysize;
		printf("# %d %d %d\n", width, height, im->Bands);
		g_object_unref(im);

    	for(j=0; resizes[i].sizes[j]; j++) {
			VipsObject *thumbnail = VIPS_OBJECT( vips_image_new() ); 
        	int isize = resizes[i].sizes[j];
        	double scale = floor(100.0 / (double)isize);
        	int stat;

			thumbnail_width = width / scale;
			thumbnail_height = height / scale;

        	snprintf(ofname, sizeof(ofname), "%d-%s", isize, 
                 basename(resizes[i].name)); /* GNU basename, not POSIX */

        	timer_start(resizes[i].name, "%d", isize);
        	stat = shrink(thumbnail, resizes[i].name, ofname);
        	timer_done();
        	check(!stat, "Shrink failed: %s", im_error_buffer());

			g_object_unref(thumbnail);

    	}/* for */
    }/* for */
}/* shrinkall*/

int
main (int argc, char **argv)
{
	GOptionContext *context;
	GError *error = NULL;

    timer_start("(none)", "initializing.");
	if( vips_init( argv[0] ) )
	        error_exit( "unable to start VIPS" );
    timer_done();

    context = g_option_context_new( "- cwtest shrink" );

	g_option_context_add_group( context, vips_get_option_group() );

	if( !g_option_context_parse( context, &argc, &argv, &error ) ) {
		if( error ) {
			fprintf( stderr, "%s\n", error->message );
			g_error_free( error );
		}

		error_exit( "try \"%s --help\"", g_get_prgname() );
	}

    parseArgs(argc, argv);
    shrinkall();
    print_times();

	vips_shutdown();
    
    return (0);
}/* main */

