
use strict;
use warnings;

require "util" ;

use vars qw( $Inc $Perl $script ) ;

if ($^O eq 'MSWin32') {
$script = <<'EOF' ;

use Filter::sh q(tr [A-E][I-M] [a-e][i-m] 2>nul) ;
use Filter::sh q(tr [N-Z] [n-z] 2>nul) ;

EOF
}
else {
$script = <<'EOF' ;

use Filter::sh q(tr '[A-E][I-M]' '[a-e][i-m]') ;
use Filter::sh q(tr '[N-Z]' '[n-z]') ;

EOF
}

$script .= <<'EOF' ;

$A = 2 ;
PRINT "A = $A\N" ;

PRINT "HELLO JOE\N" ;
PRINT <<EOM ;
MARY HAD 
A
LITTLE
LAMB
EOM
PRINT "A (AGAIN) = $A\N" ;
EOF

my $filename = 'sh.test' ;
writeFile($filename, $script) ;

my $expected_output = <<'EOM' ;
a = 2
Hello joe
mary Had 
a
little
lamb
a (aGain) = 2
EOM

my $a = `$Perl $Inc $filename 2>&1` ;
 
print "1..2\n" ;
ok(1, ($? >> 8) == 0) ;
ok(2, $a eq $expected_output) ;

unlink $filename ;

