use ExtUtils::MakeMaker;

# uncomment next line when 5.002 hits the streets.
#require 5.002 ;

WriteMakefile(
	NAME      => 'Filter',
	VERSION   => '1.06',
	'linkext'   => {LINKTYPE => ''}
);

sub MY::test {
  q#

TEST_VERBOSE=0

test :: all
	FULLPERL=$(FULLPERL) ; export FULLPERL ; \
	$(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use Test::Harness qw(&runtests $$verbose); $$verbose=$(TEST_VERBOSE); runtests @ARGV;' t/*.t

mytest :: all
	FULLPERL=$(FULLPERL) ; export FULLPERL ; \
	$(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) mytest
#  
}

