/* 
 * Filename : tee.xs
 * 
 * Author   : Paul Marquess 
 * Date     : 20th June 1995
 * Version  : 1.0
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static I32
filter_tee(idx, buf_sv, maxlen)
    int idx;
    SV * buf_sv ;
    int maxlen;
{
    I32 len;
    FILE * fil = (FILE*) SvIV(FILTER_DATA(idx)) ;
    int old_len = SvCUR(buf_sv) ;
 
    if ( (len = FILTER_READ(idx+1, buf_sv, maxlen)) <=0 ) {
        /* error or eof */
	PerlIO_close(fil) ;
        filter_del(filter_tee);      /* remove me from filter stack */
        return len;
    }

    /* write to the tee'd file */
    PerlIO_write(fil, SvPVX(buf_sv) + old_len, len - old_len) ;

    return SvCUR(buf_sv);
}

MODULE = Filter::tee	PACKAGE = Filter::tee

PROTOTYPES:	DISABLE

void
import(module, filename)
    SV *	module = NO_INIT
    char *	filename
    CODE:
	SV   * stream = newSViv(0) ;
	FILE * fil ;
	char * mode = "w" ;

	filter_add(filter_tee, stream);
	/* check for append */
	if (*filename == '>') {
	    ++ filename ;
	    if (*filename == '>') {
	        ++ filename ;
		mode = "a" ;
	    }
	}
	if ((fil = PerlIO_open(filename, mode)) == NULL) 
	    croak("Filter::tee - cannot open file '%s': %s", 
			filename, Strerror(errno)) ;

	/* save the tee'd file handle */
	SvIV_set(stream, (IV)fil) ;

