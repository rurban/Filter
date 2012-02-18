package
  Try ;
 
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
