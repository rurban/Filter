package Filter::Util::Call ;

require 5.002 ;
require DynaLoader;
require Exporter;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw( filter_add filter_del filter_read filter_read_exact) ;
$VERSION = 1.01 ;

use Carp ;
use strict ;
#$^W = 1 ;

sub filter_read_exact($)
{
    my ($size)   = @_ ;
    my ($left)   = $size ;
    my ($status) ;

    croak ("filter_read_exact: size parameter must be > 0")
	unless $size > 0 ;

    # try to read a block which is exactly $size bytes long
    while ($left and ($status = filter_read($left)) > 0) {
        $left = $size - length $_ ;
    }

    # EOF with pending data is a special case
    return 1 if $status == 0 and length $_ ;

    return $status ;
}

sub filter_add($)
{
    my($obj) = @_ ;

    # If the parameter isn't already a reference, make it one.
    $obj = \$obj unless ref $obj ;

    # finish off the installation of the filter in C.
    Filter::Util::Call::real_import(bless ($obj, (caller)[0]), (caller)[0]) ;
}

bootstrap Filter::Util::Call ;

1;
__END__

=head1 NAME

Filter::Util::Call - Perl Source Filter

=head1 DESCRIPTION

This module provides you with the framework to write I<Source Filters>
in Perl.

A I<Perl Source Filter> takes the form of a Perl module with the
following minimal structure:

    package MyFilter ;
    
    use Filter::Util::Call ;

    sub import
    {
        my($type, @arguments) = @_ ;
    
        filter_add([]) ;
    }
    
    sub filter
    {
        my($self) = @_ ;
        my($status) ;
    
        $status = filter_read() ;
    
        $status ;
    }
    
    1 ;

To make use of the filter module above, place the line below in a Perl
source file.

    use MyFilter; 

In fact, the skeleton module shown above is a fully functional I<Source
Filter>, albeit a fairly useless one. All it does is filter the source
stream without modifying it at all.

As you can see this particular module consists of a C<use> statement
and two methods, namely C<import> and C<filter>. Each of these will
will be discussed.

=head2 B<use Filter::Util::Call>

The following functions are exported by C<Filter::Util::Call>:

    filter_add()
    filter_read()
    filter_read_exact()
    filter_del()

=head2 B<import()>

The C<import> method is used to create an instance of the filter. It is
called indirectly by Perl when it encounters the C<use MyFilter> line
in a source file (See L<perlfunc/import> for more details on
C<import>).

It will always have at least one parameter automatically passed by Perl
- this corresponds to the name of the package. In the example above
that will be C<"MyFilter">.

Apart from the first parameter, import can accept an optional list of
parameters. These can be used to pass parameters to the filter. For
example:

    use MyFilter qw(a b c) ;

will result in the C<@_> array having the following values:

    @_ [0] => "MyFilter"
    @_ [1] => "a"
    @_ [2] => "b"
    @_ [3] => "c"

Before terminating, the C<import> function must explicitly install the
filter by calling C<filter_add>.

B<filter_add()>

The function, C<filter_add>, actually installs the filter. It takes one
parameter which should be a reference. This reference is used to store
context information. The reference will be I<blessed> into the package
by C<filter_add>. See the filters at the end of this documents
for examples of using context information.

=head2 B<filter()>

The C<filter> method is where the main processing for the filter is
done.

It expects a single parameter, C<$self>. This is the same reference
that was passed to C<filter_add> but is now blessed into the filter's
package. See the example filters later on for details of using
C<$self>.

=over 5

=item B<$_>

Although C<$_> doesn't actually appear explicitly in the sample filter
above, it is implicitly used in a number of places.

Firstly, when C<filter> is called, a local copy of C<$_> will be
created for the method. It will always contain the empty string at this
point.

Next, both C<filter_read> and C<filter_read_exact> will append any
source data that is read to the end of C<$_>.

Finally, when C<filter> is finished processing, it is expected to
return the filtered source using C<$_>.

This implicit use of C<$_> greatly simplifies the filter.

=item B<$status>

The status value that is returned by the user's C<filter> method and
the C<filter_read> and C<read_exact> functions take the same set of
values, namely:

    < 0  Error
    = 0  EOF
    > 0  OK

=item B<filter_read> and B<filter_read_exact>

These functions are used by the filter to obtain either a line or block
from the next filter in the chain or the actual source file of there
aren't any other filters.

The function C<filter_read> takes two forms:

    $status = filter_read() ;
    $status = filter_read($size) ;

The first form is used to request a I<line>, the second requests a
I<block>.

In the line mode, C<filter_read> will append the next source line to
the end of the C<$_> scalar.

In block mode, C<filter_read> will append a block of data which is <=
C<$size> to the end of the C<$_> scalar. It is important to emphasise
the that C<filter_read> will not necessarily read a block which is
I<precisely> C<$size> bytes.

If you need to be able to read a block which has an exact size, you can
use the function C<filter_read_exact>. It works identically to
C<filter_read> in block mode, except it will try to read a block which
is exactly C<$size> bytes in length. The only circumstances when it
will not return a block which is C<$size> bytes long is on EOF or
error.

It is I<very> important to check the value of C<$status> after I<every>
call to C<filter_read> or C<filter_read_exact>.

=item B<filter_del>

The function, C<filter_del>, is used to disable the current filter. It
does not affect the running of the filter. All it does is tell Perl not
to call filter any more.

See L<Example 4: Using filter_del> for details.

=back

=head1 EXAMPLES

Here are a few examples which illustrate the key concepts - as such
most of them are of little practical use.

=head2 Example 1: A simple filter.

Below is a filter which is hard-wired to replace all occurrences of the
string C<"Joe"> to C<"Jim">. Not particularly useful, but it is the
first example and I wanted to keep it simple.

    package Joe2Jim ;
    
    use Filter::Util::Call ;

    sub import
    {
        my($type) = @_ ;
    
        filter_add(bless []) ;
    }
    
    sub filter
    {
        my($self) = @_ ;
        my($status) ;
    
        s/Joe/Jim/g
            if ($status = filter_read()) > 0 ;
        $status ;
    }
    
    1 ;

Here is an example of using the filter:

    use Joe2Jim ;
    print "Where is Joe?\n" ;

And this is what the script above will print:

    Where is Jim?

=head2 Example 2: Using the context

The previous example was not particularly useful. To make it more
general purpose we will make use of the context data and allow any
arbitrary I<from> and I<to> strings to be used. To reflect its enhanced
role, the filter is called C<Subst>.

    package Subst ;

    use Filter::Util::Call ;
    use Carp ;
 
    sub filter
    {
        my ($self) = @_ ;
        my ($status) ;
        my ($from) = $self->[0] ;
        my ($to) = $self->[1] ;
 
        s/$from/$to/
            if ($status = filter_read()) > 0 ;
        $status ;
    }
 
    sub import
    {
        my ($self, @args) = @_ ;
        croak("usage: use Subst qw(from to)")
            unless @args == 2 ;
        filter_add([ @args ]) ;
    }
 
    1 ;
 
and is used like this:
 
    use Subst qw(Joe Jim) ;
    print "Where is Joe?\n" ;


=head2 Example 3: Using the context within the filter

Here is a filter which a variation of the C<Joe2Jim> filter. As well as
substituting all occurrences of C<"Joe"> to C<"Jim"> it keeps a count of
the number of substitutions made in the context object.

Once EOF is detected (C<$status> is zero) the filter will insert an
extra line into the source stream. When this extra line is executed it
will print a count of the number of substitutions actually made.
Note that C<$status> is set to C<1> in this case.

    package Count ;
 
    use Filter::Util::Call ;
 
    sub filter
    {
        my ($self) = @_ ;
        my ($status) ;
 
        if (($status = filter_read()) > 0 ) {
            s/Joe/Jim/g ;
	    ++ $$self ;
        }
	elsif ($$self >= 0) { # EOF
            $_ = "print q[Made ${$self} substitutions\n]" ;
            $status = 1 ;
	    $$self = -1 ;
        }

        $status ;
    }
 
    sub import
    {
        my ($self) = @_ ;
        my ($count) = 0 ;
        filter_add(\$count) ;
    }
 
    1 ;


Here is a script which uses it:

    use Count ;
    print "Hello Joe\n" ;
    print "Where is Joe\n" ;

Outputs:

    Hello Jim
    Where is Jim
    Made 2 substitutions


=head2 Example 4: Using filter_del

Another variation on a theme. This time we will modify the C<Subst>
filter to allow a starting and stopping pattern to be specified as well
as the I<from> and I<to> patterns. If you know the I<vi> editor, it is
the equivalent of this command:

    :/start/,/stop/s/from/to/

When used as a filter we want to invoke it like this:

    use NewSubst qw(start stop from to) ;

Here is the module.

    package NewSubst ;

    use Filter::Util::Call ;
    use Carp ;
 
    sub filter
    {
        my ($self) = @_ ;
        my ($status) ;
 
        if (($status = filter_read()) > 0) {

            $self->{Found} = 1
                if $self->{Found} == 0 and  /$self->{Start}/ ;

            if ($self->{Found}) {
                s/$self->{From}/$self->{To}/ ;
	        filter_del() if /$self->{Stop}/ ;
            }
            
        }
        $status ;
    }
 
    sub import
    {
        my ($self, @args) = @_ ;
        croak("usage: use Subst qw(start stop from to)")
            unless @args == 4 ;

        filter_add( { Start => $args[0],
                      Stop  => $args[1],
                      From  => $args[2],
                      To    => $args[3],
                      Found => 0 }
                  ) ;
    }
 
    1 ;



=head1 AUTHOR

Paul Marquess 

=head1 DATE

11th December 1995

=cut

