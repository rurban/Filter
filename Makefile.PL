use ExtUtils::MakeMaker;

BEGIN
{
    die "Filters needs Perl version 5.004 or better, you have $]\n"
	if $] < 5.004 ;

    warn "Perl 5.6.0 or better is strongly recommended for Win32\n"
	if $^O eq 'MSWin32' && $] < 5.006 ;
}

WriteMakefile(
	NAME      => 'Filter',
	VERSION   => '1.20',
	'linkext'   => {LINKTYPE => ''},
	'dist'	  =>	{COMPRESS=>'gzip', SUFFIX=>'gz'},
	($] >= 5.005
	    ? (ABSTRACT	=> 'Source Filters',
	       AUTHOR  	=> 'Paul Marquess <Paul.Marquess@btinternet.com>')
	    : ()
	),
	) ;

