
# check that the filters are destroyed in the correct order by
# installing two different types of filter. If they don't get destroyed
# in the correct order we should get a "filter_del can only delete in
# reverse order" error

# skip this set of tests is running on anything less than 5.004_55
if ($] < 5.004_55) {
    print "1..0\n";
    exit 0;
}

use strict;
use warnings;

require "./filter-util.pl" ;

use vars qw( $Inc $Perl) ;

my $file = "tee.test" ;
my $module = "Try";
my $tee1 = "tee1" ;


writeFile("${module}.pm", <<EOM, <<'EOM') ;
package ${module} ;
 
EOM
use Filter::Util::Call ;
sub import { 
    filter_add(
        sub {
 
            my ($status) ;
 
            if (($status = filter_read()) > 0) {
                s/ABC/DEF/g 
            }
            $status ;
        } ) ;
}
 
1 ;
EOM

my $fil1 = <<"EOM";
use $module ;

print "ABC ABC\n" ;

EOM

writeFile($file, <<"EOM", $fil1) ;
use Filter::tee '>$tee1' ;
EOM

my $a = `$Perl $Inc $file 2>&1` ;

print "1..3\n" ;

ok(1, ($? >> 8) == 0) ;
#print "|$a|\n";
ok(2, $a eq <<EOM) ;
DEF DEF
EOM

ok(3, $fil1 eq readFile($tee1)) ;

unlink $file or die "Cannot remove $file: $!\n" ;
unlink $tee1 or die "Cannot remove $tee1: $!\n" ;
