use ExtUtils::MakeMaker;

require 5.002 ;

WriteMakefile(
	NAME      => 'Filter',
	VERSION   => '1.15',
	'linkext'   => {LINKTYPE => ''},
	'dist'	  =>	{COMPRESS=>'gzip', SUFFIX=>'gz'},
	) ;

