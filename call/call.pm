package Filter::call ;

use Carp ;

require DynaLoader;
@ISA = qw(DynaLoader);


sub import
{
    my($self, $module, @args) = @_ ;
    my($obj) ;

    croak "Usage: use Filter::call qw(module [args...])\n" 
	unless $module ;

    # load the user defined perl filter module
    eval "use $module qw() ;" ;
    croak $@ if $@ ;

    # create an instance of the module
    eval "\$obj = new $module qw(@args) ;" ;
    croak $@ if $@ ;

    # make 'filter_read' directly accessible from the users module
    # without having to specify the Filter::call package.
    *{"${module}::filter_read"} = \&{"Filter::call::filter_read"} ;

    # Finally, finish off the installation of the filter in C.
    Filter::call::real_import($self, $obj, $module) ;
}

bootstrap Filter::call ;
1;
__END__

=head1 NAME
 
Filter::call - perl source filter
 
=head1 SYNOPSIS
 
    use Filter::call qw(module args...);
 
=head1 DESCRIPTION

This module allows you to filter a source file using a filter written in
Perl.

More needs added here.

=head1 AUTHOR
 
Paul Marquess <pmarquess@bfsec.bt.co.uk>
 
=head1 DATE
 
30th June 1995.
 
=cut

