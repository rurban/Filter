package Filter::decrypt ;

require DynaLoader;
@ISA = qw(DynaLoader);

bootstrap Filter::decrypt ;
1;
__END__

=head1 NAME

Filter::decrypt - decrypt source filter

=head1 SYNOPSIS

    use Filter::decrypt ;

=head1 DESCRIPTION

This is a sample decrypting source filter.

It is I<not> intended to be used for real as supplied. Consider it to
be a sampler from which you can develop your own decryption filter.

It is worth noting that a decryption filter can I<never> provide
complete security against attack. At some point the parser within Perl
needs to be able to scan the original decrypted source. Fragments of
the source will exist for a while in memory.

The best you can hope to achieve by decrypting your Perl source using a
filter is to make it impractical to crack.

Given that proviso, there are a number of things you can do to make
life more difficult for the prospective cracker.

=over 5

=item 1.

Strip the Perl binary to remove all symbols.

=item 2.

Build the decrypt extension using static linking. If the extension is
provided as a dynamic module, there is nothing to stop someone from
linking it at run time with a modified Perl binary.

=item 3.

Do not build Perl with C<-DDEBUGGING>. If you do then your source can
be retrieved with the C<-Dp> command line option.

=item 4.

Do not build Perl with C debugging support enabled.

=item 5.

Do not implement the decryption filter as a sub-process (like the cpp
source filter). It is possible to peek into the pipe that connects to
the sub-process.

=item 6.

Do not use the decrypt filter as-is. The algorithm used in this filter
has been purposefully left simple.

=back

If you feel that the source filtering mechanism is not secure enough
you could try using the unexec/undump method. See the Perl FAQ for
further details.

=head1 AUTHOR

Paul Marquess <pmarquess@bfsec.bt.co.uk>

=head1 DATE

20th June 1995.

=cut
