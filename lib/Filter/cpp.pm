package Filter::cpp;
 
use Config ;
use Carp ;
use Filter::Util::Exec ;
use strict;
use vars qw($VERSION);

$VERSION = '1.01' ;

sub import 
{ 
    my($self, @args) = @_ ;

    #require "Filter/exec.pm" ;

    if ($^O eq 'MSWin32') {
        # assume GNU cpp is installed
        Filter::Util::Exec::filter_add ($self, 'cmd', '/c', 
		"cpp.exe 2>nul") ;
    }
    else {
        croak ("Cannot find cpp")
	    if $Config{'cppstdin'} eq '' ;
        Filter::Util::Exec::filter_add ($self, 'sh', '-c', 
		"$Config{'cppstdin'} $Config{'cppminus'} 2>/dev/null") ;
    }
}

1 ;
__END__

=head1 NAME

Filter::cpp - cpp source filter

=head1 SYNOPSIS

    use Filter::cpp ;

=head1 DESCRIPTION

This source filter pipes the current source file through the C
pre-processor (cpp) if it is available.

As with all source filters its scope is limited to the current source
file only. Every file you want to be processed by the filter must have a

    use Filter::cpp ;

near the top.

Here is an example script which uses the filter:

    use Filter::cpp ;

    #define FRED 1
    $a = 2 + FRED ;
    print "a = $a\n" ;
    #ifdef FRED
    print "Hello FRED\n" ;
    #else
    print "Where is FRED\n" ;
    #endif

And here is what it will output:

    a = 3
    Hello FRED

=head1 AUTHOR

Paul Marquess 

=head1 DATE

11th December 1995.

=cut

