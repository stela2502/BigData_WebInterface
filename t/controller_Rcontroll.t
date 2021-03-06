use strict;
use warnings;
use Test::More;


unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

ok( my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'BigData_Webinterface'), 'Created mech object' );

$mech->get_ok( 'http://localhost/rcontroll/index/LUNBIO00000000000001/' );

print $mech->content();
done_testing();
