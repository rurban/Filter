
require "util" ;
use Cwd ;
$here = getcwd ;

$Inc = $Inc ; # keep -w happy
$Perl = $Perl ;


$filename = "call.tst" ;
$module   = "MyTest" ;
$module2  = "MyTest2" ;
$module3  = "MyTest3" ;
$module4  = "MyTest4" ;
$module5  = "MyTest5" ;
$nested   = "nested" ;
$block   = "block" ;

print "1..20\n" ;

# Test error cases
##################

# no module name specified
##########################

$a = `$Perl $Inc -e "use Filter::call ; "  2>&1` ;

ok(1, ($? >>8) != 0) ;
ok(2, $a =~ /^Usage: use Filter::call qw\(module \[args...]/) ;

# module name doesn't exist
###########################

$a = `$Perl $Inc -e "use Filter::call 'bad__1' ;"  2>&1` ;
ok(3, ($? >>8) != 0) ;
ok(4, $a =~ /^Can't locate bad__1.pm in \@INC/ ) ;


# no new function in module
###########################

writeFile("${module}.pm", <<EOM) ;
package ${module} ;

1 ;
EOM

$a = `$Perl $Inc -e "use Filter::call '${module}' ;"  2>&1` ;
ok(5, ($? >>8) != 0) ;
ok(6, $a =~ /^Can't locate object method "new" via package "MyTest"/) ;


# no filter function in module 
###############################

writeFile("${module}.pm", <<EOM) ;
package ${module} ;
 
sub new { bless [] }

1 ;
EOM
 
$a = `$Perl $Inc -e "use Filter::call '${module}' ;"  2>&1` ;
ok(7, ($? >>8) != 0) ;
ok(8, $a =~ /^Can't locate object method "filter" via package "MyTest"/) ;
 
# non-error cases
#################


# a simple filter
#################

writeFile("${module}.pm", <<EOM, <<'EOM') ;
package ${module} ;
 
EOM
sub new { bless [] }

sub filter 
{ 
    my ($self, $buffer) = @_ ;
    my ($status) ;

    if ($status = filter_read($buffer)) {
	$$buffer =~ s/ABC/DEF/g
    }
    $status ;
}

1 ;
EOM
 
writeFile($filename, <<EOM, <<'EOM') ;

use Filter::call '$module' ;
EOM

use Cwd ;
$here = getcwd ;
print "I am $here\n" ;
print "some letters ABC\n" ;
$y = "ABCDEF" ;
print <<EOF ;
Alphabetti Spagetti ($y)
EOF

EOM

$a = `$Perl $Inc $filename  2>&1` ;
ok(9, ($? >>8) == 0) ;
ok(10, $a eq <<EOM) ;
I am $here
some letters DEF
Alphabetti Spagetti (DEFDEF)
EOM


# nested filters
################


writeFile("${module2}.pm", <<EOM, <<'EOM') ;
package ${module2} ;
 
EOM
sub new { bless [] }
 
sub filter
{
    my ($self, $buffer) = @_ ;
    my ($status) ;
 
    if ($status = filter_read($buffer)) {
        $$buffer =~ s/XYZ/PQR/g
    }
    $status ;
}
 
1 ;
EOM
 
writeFile("${module3}.pm", <<EOM, <<'EOM') ;
package ${module3} ;
 
EOM
sub new { bless [] }
 
sub filter
{
    my ($self, $buffer) = @_ ;
    my ($status) ;
 
    if ($status = filter_read($buffer)) {
        $$buffer =~ s/Fred/Joe/g
    }
    $status ;
}
 
1 ;
EOM
 
writeFile("${module4}.pm", <<EOM) ;
package ${module4} ;
 
use Filter::call '$module5' ;

print "I'm feeling used!\n" ;
print "Fred Joe ABC DEF PQR XYZ\n" ;
print "See you Today\n" ;
1;
EOM

writeFile("${module5}.pm", <<EOM, <<'EOM') ;
package ${module5} ;
 
EOM
sub new { bless [] }
 
sub filter
{
    my ($self, $buffer) = @_ ;
    my ($status) ;
 
    if ($status = filter_read($buffer)) {
        $$buffer =~ s/Today/Tomorrow/g
    }
    $status ;
}
 
1 ;
EOM

writeFile($filename, <<EOM, <<'EOM') ;
 
# two filters for this file
use Filter::call '$module' ;
use Filter::call '$module2' ;
require "$nested" ;
use $module4 ;
EOM
 
print "some letters ABCXYZ\n" ;
$y = "ABCDEFXYZ" ;
print <<EOF ;
Fred likes Alphabetti Spagetti ($y)
EOF
 
EOM
 
writeFile($nested, <<EOM, <<'EOM') ;
use Filter::call '$module3' ;
EOM
 
print "This is another file XYZ\n" ;
print <<EOF ;
Where is Fred?
EOF
 
EOM

$a = `$Perl $Inc $filename  2>&1` ;
ok(11, ($? >>8) == 0) ;
ok(12, $a eq <<EOM) ;
I'm feeling used!
Fred Joe ABC DEF PQR XYZ
See you Tomorrow
This is another file XYZ
Where is Joe?
some letters DEFPQR
Fred likes Alphabetti Spagetti (DEFDEFPQR)
EOM



# using the module context 
##########################


writeFile("${module2}.pm", <<EOM, <<'EOM') ;
package ${module2} ;
 
EOM
sub new 
{ 
    my ($type) = shift ;
    my (@strings) = @_ ;

  
    bless [@strings] 
}
 
sub filter
{
    my ($self, $buffer) = @_ ;
    my ($status) ;
    my ($pattern) ;
 
    if ($status = filter_read($buffer)) {
	foreach $pattern (@$self)
          { $$buffer =~ s/$pattern/PQR/g }
    }

    $status ;
}
 
1 ;
EOM
 
 
writeFile($filename, <<EOM, <<'EOM') ;
 
use Filter::call qw( $module2 XYZ KLM) ;
use Filter::call qw( $module2 ABC NMO) ;
EOM
 
print "some letters ABCXYZ KLM NMO\n" ;
$y = "ABCDEFXYZKLMNMO" ;
print <<EOF ;
Alphabetti Spagetti ($y)
EOF
 
EOM
 
$a = `$Perl $Inc $filename  2>&1` ;
ok(13, ($? >>8) == 0) ;
ok(14, $a eq <<EOM) ;
some letters PQRPQR PQR PQR
Alphabetti Spagetti (PQRDEFPQRPQRPQR)
EOM

# multi line test
#################


writeFile("${module2}.pm", <<EOM, <<'EOM') ;
package ${module2} ;
 
EOM
sub new 
{ 
    my ($type) = shift ;
    my (@strings) = @_ ;

  
    bless [] 
}
 
sub filter
{
    my ($self, $buffer) = @_ ;
    my ($status) ;
 
    # read first line
    if ($status = filter_read($buffer)) {
	chop $$buffer ;
	# and now the second line (it will append)
        $status = filter_read($buffer) ;
    }

    $status ;
}
 
1 ;
EOM
 
 
writeFile($filename, <<EOM, <<'EOM') ;
 
use Filter::call qw( $module2 ) ;
EOM
print "don't cut me 
in half\n" ;
print  
<<EOF ;
appen
ded
EO
F
 
EOM
 
$a = `$Perl $Inc $filename  2>&1` ;
ok(15, ($? >>8) == 0) ;
ok(16, $a eq <<EOM) ;
don't cut me in half
appended
EOM

# Block test
#############

writeFile("${block}.pm", <<EOM, <<'EOM') ;
package ${block} ;
 
EOM
sub new 
{ 
    my ($type) = shift ;
    my (@strings) = @_ ;

  
    bless [@strings] 
}
 
sub filter
{
    my ($self, $buffer) = @_ ;
    my ($status) ;
    my ($pattern) ;
 
    filter_read($buffer, 20)  ;
}
 
1 ;
EOM

$string = <<'EOM' ;
print "hello mum\n" ;
$x = 'me ' x 3 ;
print "Who wants it?\n$x\n" ;
EOM


writeFile($filename, <<EOM, $string ) ;
use Filter::call '$block' ;
EOM
 
$a = `$Perl $Inc $filename  2>&1` ;
ok(17, ($? >>8) == 0) ;
ok(18, $a eq <<EOM) ;
hello mum
Who wants it?
me me me 
EOM

# use in the filter
####################

writeFile("${block}.pm", <<EOM, <<'EOM') ;
package ${block} ;
 
EOM
use Cwd ;

sub new 
{ 
    my ($type) = shift ;
    my (@strings) = @_ ;

  
    bless [@strings] 
}
 
sub filter
{
    my ($self, $buffer) = @_ ;
    my ($status) ;
    my ($here) = getcwd ;
 
    if ($status = filter_read($buffer)) {
        $$buffer =~ s/DIR/$here/g
    }
    $status ;
}
 
1 ;
EOM

writeFile($filename, <<EOM, <<'EOM') ;
use Filter::call '$block' ;
EOM
print "We are in DIR\n" ;
EOM
 
$a = `$Perl $Inc $filename  2>&1` ;
ok(19, ($? >>8) == 0) ;
ok(20, $a eq <<EOM) ;
We are in $here
EOM

unlink $filename ;
unlink "${module}.pm" ;
unlink "${module2}.pm" ;
unlink "${module3}.pm" ;
unlink "${module4}.pm" ;
unlink "${module5}.pm" ;
unlink $nested ;
unlink "${block}.pm" ;
exit ;

