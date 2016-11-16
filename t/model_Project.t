use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'BigData_Webinterface::Model::Project' }
use BigData_Webinterface::Model::ACL;

## here I need to check the data structures that can be shown to the user and the function to create and manipulate data.

my ( $value, @values, $tmp, $exp );

my $c = test::c->new();

system( 'rm -Rf ' . "$FindBin::Bin" . "/data/Output/Project/*" );

ok( $c->model('Rinterface')->{'path'} eq $c->session_path(),
	"Rinterface path is set right" );

my $OBJ =
  BigData_Webinterface::Model::Project->new( 'BigData_Webinterface',
	{ dbh => variable_table->getDBH() } );

ok(
	ref($OBJ) eq "BigData_Webinterface::Model::Project",
	"could get instance of BigData_Webinterface::Model::Project"
);

$OBJ->{'projects'}->create('projects');

## reinit!
$OBJ =
  BigData_Webinterface::Model::Project->new( 'BigData_Webinterface',
	{ dbh => variable_table->getDBH() } );

ok( $OBJ->{projects}->{'next_id'} == 1, "right project id (1)" );

ok( "LUNBIO" . sprintf( "%014d", 1 ) eq "LUNBIO00000000000001",
	"LUNBIO" . sprintf( "%014d", 1 ) );

#print "\$exp = " . root->print_perl_var_def( $value->{'header'} ) . ";\n";
$value = $OBJ->{'projects'}->{'data_handler'}->{'scientistTable'}->AddDataset(
	{
		name        => "Test User",
		'username'  => "test-use",
		'workgroup' => 'bioinformatics test unit',
		position    => 'dummy',
		email       => 'nonw@nowhere.com',
		'pw'        => "thisIsNoPW"
	}
);
ok( $value > 0, "I could add a user" );

$value = $OBJ->{'projects'}->AddDataset(
	{
		'description' => "This is a test of the projects table interface #1",
		'owner'       => 1,
	}
);

$value = $OBJ->{'projects'}->get_data_table_4_search(
	{
		'search_columns' => [''],
		'where'          => [],
	},
);

ok( ref($value) eq "data_table", "search was positive" );

ok( $value > 0, "I could add a project" );

$exp = [
	sort ( 'projects.id', 'projects.name',
		'projects.description',      'projects.owner',
		'scientists.id',             'scientists.username',
		'scientists.name',           'scientists.workgroup',
		'scientists.position',       'scientists.email',
		'scientists.action_gr_id',   'scientists.roles_list_id',
		'scientists.pw',             'scientists.salt',
		'role_list.id',              'role_list.list_id',
		'role_list.others_id',       'roles.id',
		'roles.rolename',            'action_group_list.id',
		'action_group_list.list_id', 'action_group_list.others_id',
		'action_groups.id',          'action_groups.name',
		'action_groups.description' )
];

is_deeply( [ sort( @{ $value->{'header'} } ) ],
	$exp, "both project and ACL data is accessible" );

#print "\$exp = ".root->print_perl_var_def($value->get_line_asHash(0)).";\n";
$exp = {
	'action_group_list.id'        => undef,
	'action_group_list.list_id'   => undef,
	'action_group_list.others_id' => undef,
	'action_groups.description'   => undef,
	'action_groups.id'            => undef,
	'action_groups.name'          => undef,
	'projects.description' =>
	  'This is a test of the projects table interface #1',
	'projects.id'              => '1',
	'projects.name'            => 'LUNBIO00000000000001',
	'projects.owner'           => '1',
	'role_list.id'             => undef,
	'role_list.list_id'        => undef,
	'role_list.others_id'      => undef,
	'roles.id'                 => undef,
	'roles.rolename'           => undef,
	'scientists.action_gr_id'  => '0',
	'scientists.email'         => 'nonw@nowhere.com',
	'scientists.id'            => '1',
	'scientists.name'          => 'Test User',
	'scientists.position'      => 'dummy',
	'scientists.pw'            => 'thisIsNoPW',
	'scientists.roles_list_id' => '0',
	'scientists.salt'          => '0',
	'scientists.username'      => 'test-use',
	'scientists.workgroup'     => 'bioinformatics test unit'
};

is_deeply( $value->get_line_asHash(0), $exp, "right data created" );

$OBJ->{'projects'}->create('projects');

## reinit!
$OBJ =
  BigData_Webinterface::Model::Project->new( 'BigData_Webinterface',
	{ dbh => variable_table->getDBH() } );

$OBJ->register_project( $c,
	{ 'description' => 'This is a test of the projects table interface #1' } );

#print "\$exp = ".root->print_perl_var_def( $c->session->{'active_projects'} ).";\n";
$exp = {
	'LUNBIO00000000000001' => {
		'R'    => '0',
		'path' => '' . $c->session_path() . '/LUNBIO00000000000001/'
	}
};
is_deeply( $c->session->{'active_projects'},
	$exp, "project has been added to the session" );

ok( -f $c->session_path() . "server_0.R", "the server script exists" );

open( IN, "<" . $c->session_path() . "server_0.R" );
$value = [ map { chomp; $_ } <IN> ];

#print "\$exp = " . root->print_perl_var_def($value) . ";\n";

$exp = [
'logfile <- \''. $c->session_path().'/LUNBIO00000000000001/scripts/test-use_automatic_commands.R\'',
'infile <- \''. $c->session_path().'/0.input.R\'',
	'system( \'touch logfile\')',
	'server <- function(){',
	'  while(TRUE){',
	'        if ( file.exists(infile) ) {',
'                while ( file.exists( paste(infile,\'log\', sep=\'.\' ) ) ) {',
	'                        Sys.sleep( 2 )',
	'                }',
	'                system( paste(\'cat\', infile, \'>>\', logfile ))',
'                capture.output(source( infile ), file= logfile, append =T, type=\'output\' )',
	'                file.remove( infile )',
	'        }',
	'        Sys.sleep(2)',
	'  }',
	'}',
	'server()'
];

is_deeply( $value, $exp, "server script file contents" );

my $cmd =
"png( file='test.png', width=400, height=400)\nplot(1:10,1:10)\ndev.off()\nSys.sleep(5)";

$OBJ->send_2_R( $c, 'LUNBIO00000000000001', $cmd )
  ;    ## the file will 20sec not be removed!

ok( -f $c->session_path() . "0.input.R", "the server inpit file exists" );

open( IN, "<" . $c->session_path() . "0.input.R" )
  or die "I could not open the R input file\n";
$value = [ map { chomp; $_ } <IN> ];

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
$exp = [ split( "\n", $cmd ) ];

is_deeply( $value, $exp, "R input file as expected" );

close(IN);

sleep(5);

ok(
	-f $c->session_path() . "/LUNBIO00000000000001/output/test.png",
	"output figure was created '"
	  . $c->session_path()
	  . "/LUNBIO00000000000001/output/test.png'"
);

ok(
	-f $c->session_path()
	  . '/LUNBIO00000000000001/scripts/test-use_automatic_commands.R',
	"the automatic R log file"
);

&file_2_value( $c->session_path()
	  . '/LUNBIO00000000000001/scripts/test-use_automatic_commands.R' );

#print "\$exp = " . root->print_perl_var_def($value) . ";\n";
$exp = [
	'setwd( \'' . $c->session_path() . '/LUNBIO00000000000001/output/\' )',
	'png( file=\'test.png\', width=400, height=400)',
	'plot(1:10,1:10)',
	'dev.off()',
	'Sys.sleep(5)'
];

is_deeply( $value, $exp, "The automatic log file contents" );

$OBJ->send_2_R( $c, 'LUNBIO00000000000001',
	"print('I can capture the R output messages')" );

$c->model('Rinterface')->DESTROY();

ok( !-f $c->session_path() . "0.input.R", "the R input has been removed" );

&file_2_value( $c->session_path()
	  . '/LUNBIO00000000000001/scripts/test-use_automatic_commands.R' );
push( @$exp,
	"print('I can capture the R output messages')",
	"[1] \"I can capture the R output messages\"",
	"q('yes')",
	"> proc.time()",
	"   user  system elapsed "
	 );
pop( @$value); ## get rid of the variable proc time line "  0.208   0.016  11.242 " 
is_deeply( $value, $exp,
	"The automatic log file contents after server is shut down" );

#$c->model('Rinterface')->DESTROY();

done_testing();

sub file_2_value {
	my ($file) = @_;
	open( IN, "<" . $file ) or die $!;
	$value = [ map { chomp; $_ } <IN> ];
	close(IN);
}

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

package test::c;
use strict;
use warnings;
use stefans_libs::RInterface;

use FindBin;

sub new {
	my $self = {
		'config' => {
			'ncore'      => 4,
			'calcserver' => {
				'ncore'   => 32,
				'ip'      => '127.0.0.1',
				'subpage' => "/weblog/fluidigm/"
			}
		},
		'session' => {},

	};
	bless $self, shift;
	return $self;
}

sub user {
	return "test-use";
}

sub session_path {
	my ($self) = @_;
	return $self->{'p'} if ( defined $self->{'p'} );
	$self->{'p'} = "$FindBin::Bin" . "/data/Output/Project/";
	unless ( -d $self->{'p'} ) {
		mkdir( $self->{'p'} );
	}

	return $self->{'p'};
}

sub config {    ## Catalyst function
	return shift->{'config'};
}

sub session {
	my ( $self, $value ) = @_;
	unless ( defined $value ) {
		return $self->{'session'};
	}
	return $self->{'session'}->{$value};
}

sub model {     ## Catalyst function
	my ( $self, $name ) = @_;
	if ( $name eq 'Rinterface' ) {
		$self->{model}->{'Rinterface'} ||=
		  stefans_libs::RInterface->new( { path => $self->session_path() } );
		return $self->{model}->{'Rinterface'};
	}
	elsif ( $name eq "ACL" ) {
		$self->{model}->{'ACL'} ||= BigData_Webinterface::Model::ACL->new();
		return $self->{model}->{'ACL'};
	}
	return undef;
}

sub get_session_id {    ## Catalyst function
	return 1234556778;
}

package upload;
use strict;
use warnings;

sub new {
	my ( $name, $filename ) = @_;
	my $self = { 'filename' => $filename };
	bless $self, $name;
	return $self;
}

sub copy_to {
	my ( $self, $to ) = @_;
	return system("cp $self->{'filename'} $to");
}

1;
