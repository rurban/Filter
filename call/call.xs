/* 
 * Filename : call.xs
 * 
 * Author   : Paul Marquess <pmarquess@bfsec.bt.co.uk>
 * Date     : 29th June 1995
 * Version  : 1.0
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int fdebug = 0;

/* Internal defines */
#define PERL_MODULE(s)		IoBOTTOM_NAME(s)
#define PERL_OBJECT(s)		IoTOP_GV(s)

#define OUTPUT_SV(s)		s



static AV * idx_stack ;

static I32
filter_call(idx, buf_sv, maxlen)
    int idx;
    SV *buf_sv;
    int maxlen;
{
    SV   *my_sv = FILTER_DATA(idx);
    char *nl = "\n";
    char *p;
    char *out_ptr;
    int n;

    if (fdebug)
	warn("**** In filter_call - maxlen = %d, len buf = %d idx = %d\n", 
		maxlen, SvCUR(buf_sv), idx ) ;

    while (1) {

	/* anything left from last time */
	if (n = SvCUR(OUTPUT_SV(my_sv))) {

	    out_ptr = SvPVX(OUTPUT_SV(my_sv)) ;

	    if (maxlen) { 
		/* want a block */ 
		if (fdebug)
		    warn("BLOCK(%d): size = %d, maxlen = %d\n", 
			idx, n, maxlen) ;

	        sv_catpvn(buf_sv, out_ptr, maxlen > n ? n : maxlen );
		if(n <= maxlen)
	            SvCUR_set(OUTPUT_SV(my_sv), 0) ;
		else {
	            memmove(out_ptr, out_ptr+maxlen, n - maxlen);
	            SvCUR_set(OUTPUT_SV(my_sv), n - maxlen) ;
		}
	        return SvCUR(buf_sv);
	    }
	    else {
		/* want lines */
                if (p = ninstr(out_ptr, out_ptr + n - 1, nl, nl)) {

	            sv_catpvn(buf_sv, out_ptr, p - out_ptr + 1);

	    	    /* move remaining partial line down to start of string */
	            n = n - (p - out_ptr + 1);
	            memmove(out_ptr, p + 1, n); 
	            SvCUR_set(OUTPUT_SV(my_sv), n) ;
	            if (fdebug)
		        warn("recycle %d - leaving %d, returning %d [%s]", 
				idx, n, SvCUR(buf_sv), SvPVX(buf_sv)) ;

	            return SvCUR(buf_sv);
	        }
	        else /* no EOL, so append the complete buffer */
	            sv_catsv(buf_sv, OUTPUT_SV(my_sv)) ;
	    }
	    
	}


	SvCUR_set(OUTPUT_SV(my_sv), 0) ;

	/* Call the perl filter to get the line/block */
	{
	    dSP ;
	    int count ;

            if (fdebug)
		warn("gonna call %s::%s\n", PERL_MODULE(my_sv), "filter") ;

	    /* remember the current idx */
	    av_push(idx_stack, newSViv(idx)) ; 

	    PUSHMARK(sp) ;
            XPUSHs(PERL_OBJECT(my_sv)) ;  
            XPUSHs(sv_2mortal(newRV(OUTPUT_SV(my_sv)))) ;   
            PUTBACK ;
	    count = perl_call_method("filter", 0) ; 
            SPAGAIN ;
            if (count != 1)
	        croak("Filter::call - %s::filter returned %d values, 1 was expected \n", 
			count, PERL_MODULE(my_sv)) ;
    
	    n = POPi ;
	    if (fdebug)
	        warn("status = %d, length op buf = %d\n",
		     n, SvCUR(OUTPUT_SV(my_sv))) ;
            PUTBACK ;

	    sv_free(av_pop(idx_stack)) ;
	}


 	if (n <= 0)
	{
	    /* Either EOF or an error */

	    if (fdebug)
	        warn ("filter_read %d returned %d , returning %d\n", idx, n,
	            (SvCUR(buf_sv)>0) ? SvCUR(buf_sv) : n);

	    filter_del(filter_call);  

	    /* return what we have so far else signal eof */
	    return (SvCUR(buf_sv)>0) ? SvCUR(buf_sv) : n;
	}

    }
}


MODULE = Filter::call		PACKAGE = Filter::call

#define IDX		(SvIV(*av_fetch(idx_stack, -1, 0)))

int
filter_read(ref, size=0)
	SV *	ref
	int	size 
	CODE:
	{
	    SV * buffer = SvRV(ref) ;
	    int index = IDX ;

	    /* warn("buffer = %d\n", SvCUR(buffer)) ; */
	    RETVAL = FILTER_READ(index + 1, buffer, size) ;
	}
	OUTPUT:
	    RETVAL




void
real_import(module, object, perlmodule)
    SV *	module = NO_INIT
    SV *	object
    char *	perlmodule 
    PPCODE:
    {
        SV * sv = newSVpv("",0) ;

        filter_add(filter_call, sv) ;

	PERL_MODULE(sv) = savepv(perlmodule) ;
	PERL_OBJECT(sv) = newSVsv(object) ;

        SvCUR_set(OUTPUT_SV(sv), 0) ;

    }

void
unimport(...)
    PPCODE:
    /* filter_del(filter_call); */


BOOT:
    idx_stack = newAV() ;

BOOT:
    /* temporary hack to control debugging in toke.c */
    if (fdebug)
        filter_add(NULL, (fdebug) ? (SV*)"1" : (SV*)"0");  


