use ExtUtils::MakeMaker;

require 5.002 ;

WriteMakefile(
	NAME      => 'Filter',
	VERSION   => '1.16',
	'linkext'   => {LINKTYPE => ''},
	'dist'	  =>	{COMPRESS=>'gzip', SUFFIX=>'gz'},
	) ;

