package Joe2Jim ;
 
use Filter::Util::Call ;
 
sub import
{
    my($type) = @_ ;
 
    filter_add(
        sub 
        {
            my($status) ;
            s/Joe/Jim/g
                if ($status = filter_read()) > 0 ;
            $status ;
        })
}

1 ;

