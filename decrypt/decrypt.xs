/* 
 * Filename : decrypt.xs
 * 
 * Author   : Paul Marquess <pmarquess@bfsec.bt.co.uk>
 * Date     : 20th June 1995
 * Version  : 1.0
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int fdebug = 0;

/* constants specific to the encryption format */
#define CRYPT_MAGIC_1	0xff
#define CRYPT_MAGIC_2	0x00

#define HEADERSIZE	2
#define BLOCKSIZE	4


static unsigned XOR [BLOCKSIZE] = {'P', 'e', 'r', 'l' } ;


/* Internal defines */
#define FILTER_COUNT(s)		IoPAGE(s)
#define FILTER_LINE_NO(s)	IoLINES(s)
#define FIRST_TIME(s)		IoFLAGS(s)

#define ENCRYPT_SV(s)		IoTOP_GV(s)
#define ENCRYPT_BUFFER(s)	SvPVX(ENCRYPT_SV(s))
#define CLEAR_ENCRYPT_SV(s)	SvCUR_set(ENCRYPT_SV(s), 0)

#define DECRYPT_SV(s)		s
#define DECRYPT_BUFFER(s)	SvPVX(DECRYPT_SV(s))
#define CLEAR_DECRYPT_SV(s)	SvCUR_set(DECRYPT_SV(s), 0)
#define DECRYPT_BUFFER_LEN(s)	SvCUR(DECRYPT_SV(s))
#define SET_DECRYPT_BUFFER_LEN(s,n)	SvCUR_set(DECRYPT_SV(s), n)

static unsigned
Decrypt(in_sv, out_sv)
SV * in_sv ;
SV * out_sv ;
{
	/* Here is where the actual decryption takes place */

    	unsigned char * in_buffer  = (unsigned char *) SvPVX(in_sv) ;
    	unsigned char * out_buffer ;
    	unsigned size = SvCUR(in_sv) ;
    	unsigned index = size ;
    	int i ;

	/* make certain that the output buffer is big enough 		*/
	/* as the output from the decryption can never be larger than	*/
	/* the input buffer, make it that size				*/
	SvGROW(out_sv, size) ;
	out_buffer = (unsigned char *) SvPVX(out_sv) ;

        /* XOR */
        for (i = 0 ; i < size ; ++i) 
            out_buffer[i] = (unsigned char)( XOR[i] ^ in_buffer[i] ) ;

	/* input has been consumed, so set length to 0 */
	SvCUR_set(in_sv, 0) ;

	/* set decrypt buffer length */
	SvCUR_set(out_sv, index) ;

	/* return the size of the decrypt buffer */
 	return (index) ;
}

static unsigned
ReadBlock(idx, sv, size)
int idx ;
SV * sv ;
unsigned size ;
{
    /* read *exactly* size bytes from the next filter */

    int n ;
    int i = size;

    while (1) {
        n = FILTER_READ(idx, sv, i) ;
	if (n <= 0)
	    return n ;

	if (n == i)
	    return size ;

	i -= n ;
    }
}

static void
preDecrypt(idx)
    int idx;
{
    /*	If the encrypted data starts with a header or needs to do some
	initialisation it can be done here 

	In this case the encrypted data has to start with a fingerprint,
	so that is checked.
    */

    SV * sv = FILTER_DATA(idx) ;
    unsigned char * buffer ;


    /* read the header */
    if (ReadBlock(idx+1, sv, HEADERSIZE) != HEADERSIZE)
	croak("truncated file") ;

    buffer = (unsigned char *) SvPVX(sv) ;

    /* check for fingerprint of encrypted data */
    if (buffer[0] != CRYPT_MAGIC_1 || buffer[1] != CRYPT_MAGIC_2) 
            croak( "bad encryption format" );
}

static void
postDecrypt()
{
}

static I32
filter_decrypt(idx, buf_sv, maxlen)
    int idx;
    SV *buf_sv;
    int maxlen;
{
    SV   *my_sv = FILTER_DATA(idx);
    char *nl = "\n";
    char *p;
    char *out_ptr;
    int n;

    /* check if this is the first time through */
    if (FIRST_TIME(my_sv)) {

	/* Mild paranoia mode - make sure that no extra filters have 	*/
	/* been applied on the same line as the use Filter::decrypt	*/
        if (AvFILL(rsfp_filters) > FILTER_COUNT(my_sv) )
	    croak("too many filters") ; 

	/* As this is the first time through, so deal with any 		*/
	/* initialisation required 					*/
        preDecrypt(idx) ;

	FIRST_TIME(my_sv) = FALSE ;
        SvCUR_set(DECRYPT_SV(my_sv), 0) ;
        SvCUR_set(ENCRYPT_SV(my_sv), 0) ;
    }

    if (fdebug)
	warn("**** In filter_decrypt - maxlen = %d, len buf = %d idx = %d\n", 
		maxlen, SvCUR(buf_sv), idx ) ;

    while (1) {

	/* anything left from last time */
	if (n = SvCUR(DECRYPT_SV(my_sv))) {

	    out_ptr = SvPVX(DECRYPT_SV(my_sv)) ;

	    if (maxlen) { 
		/* want a block */ 
		if (fdebug)
		    warn("BLOCK(%d): size = %d, maxlen = %d\n", 
			idx, n, maxlen) ;

	        sv_catpvn(buf_sv, out_ptr, maxlen > n ? n : maxlen );
		if(n <= maxlen)
	            SvCUR_set(DECRYPT_SV(my_sv), 0) ;
		else {
	            memmove(out_ptr, out_ptr+maxlen, n - maxlen);
	            SvCUR_set(DECRYPT_SV(my_sv), n - maxlen) ;
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
	            SvCUR_set(DECRYPT_SV(my_sv), n) ;
	            if (fdebug)
		        warn("recycle %d - leaving %d, returning %d [%s]", 
				idx, n, SvCUR(buf_sv), SvPVX(buf_sv)) ;

	            return SvCUR(buf_sv);
	        }
	        else /* no EOL, so append the complete buffer */
	            sv_catsv(buf_sv, DECRYPT_SV(my_sv)) ;
	    }
	    
	}


	SvCUR_set(DECRYPT_SV(my_sv), 0) ;

	/* read from the file into the encrypt buffer */
 	if ( (n = ReadBlock(idx+1, ENCRYPT_SV(my_sv), BLOCKSIZE)) <= 0)
	{
	    /* Either EOF or an error */

	    if (fdebug)
	        warn ("filter_read %d returned %d , returning %d\n", idx, n,
	            (SvCUR(buf_sv)>0) ? SvCUR(buf_sv) : n);

	    SvCUR_set(DECRYPT_SV(my_sv), 0);

	    /* If the decrypt code needs to tidy up on EOF/error, 
		now is the time  - here is a hook */
	    postDecrypt() ; 

	    filter_del(filter_decrypt);  

	    /* return what we have so far else signal eof */
	    return (SvCUR(buf_sv)>0) ? SvCUR(buf_sv) : n;
	}

	if (fdebug)
	    warn("  filter_decrypt(%d): sub-filter returned %d: '%s'",
		idx, n, SvPV(my_sv,na));

	/* Now decrypt a block */
	n = Decrypt(ENCRYPT_SV(my_sv), DECRYPT_SV(my_sv)) ;

	if (fdebug)
	    warn("Decrypt (%d) returned %d\n", idx, n) ;

    }
}


MODULE = Filter::decrypt	PACKAGE = Filter::decrypt

void
import(module)
    SV *	module = NO_INIT
    PPCODE:
    {

        SV * sv = newSVpv("", BLOCKSIZE) ;

	/* make sure the Perl debugger isn't enabled */
	if( perldb )
	    croak("debugger disabled") ;

        filter_add(filter_decrypt, sv) ;
	FIRST_TIME(sv) = TRUE ;
	ENCRYPT_SV(sv) = newSVpv("", BLOCKSIZE) ;
        SvCUR_set(DECRYPT_SV(sv), 0) ;
        SvCUR_set(ENCRYPT_SV(sv), 0) ;

        /* remember how many filters are enabled */
        FILTER_COUNT(sv) = AvFILL(rsfp_filters) ;
	/* and the line number */
	FILTER_LINE_NO(sv) = curcop->cop_line ;

    }

void
unimport(...)
    PPCODE:
    /* filter_del(filter_decrypt); */
