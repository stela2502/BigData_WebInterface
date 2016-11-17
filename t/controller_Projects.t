use strict;
use warnings;
use Test::More;

$SIG{__WARN__} = sub {} ; # ssssssh

unless ( eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1} ) {
	plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
	exit 0;
}

ok(
	my $mech = Test::WWW::Mechanize::Catalyst->new(
		catalyst_app => 'BigData_Webinterface'
	),
	'Created mech object'
);

$mech->get_ok('http://localhost/login' );


$mech->get_ok('http://localhost/projects/index/');

$mech->submit_form_ok(
	{
		with_fields => { 'description' },
		fields      => {
			description => 'This is a test of the projects table interface #123'
		},
		
	},
	'Create a test project'
);


$mech->get_ok('http://localhost/projects/index/');


#print "\n\n\n". $mech->content() ."\n\n\n";

$mech->content_contains(
"http://localhost:3000/rcontroll/index/LUNBIO00000000000001",
	"the link to the test project has been created"
);


done_testing();
