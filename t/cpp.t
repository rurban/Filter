
require "./util" ;

$Inc = $Inc ; # keep -w happy
$Perl = $Perl ;

$script = <<'EOF' ;
use Filter::cpp ;
#define FRED 1
#define JOE

#a perl comment, not a cpp line

$a = FRED + 2 ;
print "a = $a\n" ;

require "./fred" ;

#ifdef JOE
  print "Hello Joe\n" ;
#else
  print "Where is Joe?\n" ;
#endif
EOF

$cpp_script = 'cpp.script' ;
writeFile($cpp_script, $script) ;
writeFile('fred', 'print "This is FRED, not JOE\n" ; 1 ;') ;

$expected_output = <<'EOM' ;
a = 3
This is FRED, not JOE
Hello Joe
EOM

$a = `$Perl $Inc $cpp_script 2>&1` ;

print "1..2\n" ;
ok(1, ($? >>8) == 0) ;
ok(2, $a eq $expected_output) ;

unlink $cpp_script ;
unlink 'fred' ;
