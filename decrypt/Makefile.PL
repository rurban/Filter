use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Filter::decrypt',
	VERSION   => '1.01',

	# The line below disables the dynamic link test.
	# It is only enabled here to allow the decrypt test harness
	# to run without having to build statically.
	DEFINE	  => "-DBYPASS",
);
