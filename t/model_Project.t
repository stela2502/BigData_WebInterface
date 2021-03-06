use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'BigData_Webinterface::Model::Project' }
use BigData_Webinterface::Model::ACL;
use FindBin;

## here I need to check the data structures that can be shown to the user and the function to create and manipulate data.

my ( $value, @values, $tmp, $exp );

my $c = test::c->new();

system( 'rm -Rf ' . "$FindBin::Bin" . "/data/Output/Project/*" );

ok( !-d "$FindBin::Bin" . "/data/Output/Project/LUNBIO00000000000001",
	'the project path does not exist - good!' );
ok(
	$c->model('Rinterface')->{'path'} eq "$FindBin::Bin" . "/data/Output/Project",
	"Rinterface path is set right '"
	  . $c->model('Rinterface')->{'path'}
	  . "' != '"
	  . "$FindBin::Bin" . "/data/Output/Project". "'"
);

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
		'projects.md5_sum',            'projects.description',
		'projects.owner',              'scientists.id',
		'scientists.username',         'scientists.name',
		'scientists.workgroup',        'scientists.position',
		'scientists.email',            'scientists.action_gr_id',
		'scientists.roles_list_id',    'scientists.pw',
		'scientists.salt',             'role_list.id',
		'role_list.list_id',           'role_list.others_id',
		'roles.id',                    'roles.rolename',
		'action_group_list.id',        'action_group_list.list_id',
		'action_group_list.others_id', 'action_groups.id',
		'action_groups.name',          'action_groups.description' )
];

is_deeply( [ sort( @{ $value->{'header'} } ) ],
	$exp, "both project and ACL data are accessible" );

#print "\$exp = ".root->print_perl_var_def($value->get_line_asHash(0)).";\n";
$exp = {
	'action_group_list.id'        => undef,
	'action_group_list.list_id'   => undef,
	'action_group_list.others_id' => undef,
	'action_groups.description'   => undef,
	'action_groups.id'            => undef,
	'action_groups.name'          => undef,
	'projects.md5_sum'            => '70198284474acc7b685b690963a848f7',
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

unlink( $c->session_path('LUNBIO00000000000001')
	  . 'scripts/test-use_automatic_commands.R' )
  if ( -f $c->session_path('LUNBIO00000000000001')
	. 'scripts/test-use_automatic_commands.R' );

$OBJ->register_project( $c,
	{ 'description' => 'This is a test of the projects table interface #1' } );

#print "\$exp = ".root->print_perl_var_def( $c->session->{'active_projects'} ).";\n";

$exp = {
	'LUNBIO00000000000001' => {
		'R'       => '0',
		'logfile' => $c->session_path('LUNBIO00000000000001')
		  . 'scripts/test-use_automatic_commands.R',
		'outpath' => $c->session_path('LUNBIO00000000000001') . 'output/',
		'path'    => $c->session_path('LUNBIO00000000000001'),
	}
};

is_deeply( $c->session->{'active_projects'},
	$exp, "project has been added to the session" );


ok( -f $c->model('Rinterface')->{'path'}. "/server_0.R", "the server script exists" );

sleep(4);    # wait untill the server has started.
#ok(
#	-f $c->session_path('LUNBIO00000000000001')
#	  . "scripts/test-use_automatic_commands.R",
#	"the server log exists"
#);

ok( @{ &is_running(0) } > 2, "server 0 started and running" );

#&file_2_value( $c->session_path('LUNBIO00000000000001') . 'scripts/test-use_automatic_commands.R' );

#print "\$exp = " . root->print_perl_var_def($value) . ";\n";
#$exp =  [ 'setwd( \'' . $c->session_path('LUNBIO00000000000001') . 'output/\' )' ];
#is_deeply( $value, $exp, "the server log directly after the start" );

open( IN, "<" . $c->model('Rinterface')->{'path'} . "/server_0.R" );
$value = [ map { chomp; $_ } <IN> ];
close(IN);
#print "\$exp = " . root->print_perl_var_def($value) . ";\n";
print "This is the script:\n".join("\n", @$value ) ."\n";


$exp = [
'## the strage var names are to not interfere with user defined variable names',
'LoGfIlE <- \'' . $c->session_path('LUNBIO00000000000001') . 'scripts/test-use_automatic_commands.R\'',
'LoCkFiLe <- \'' . $c->model('Rinterface')->{'path'} . '/0.input.lock\'',
'InFiLe <- \'' . $c->model('Rinterface')->{'path'}  . '/0.input.R\'',

 "setwd( '".$c->session_path('LUNBIO00000000000001').'output/'."' )",
'system( paste(\'touch\', LoGfIlE) )',
'identifyMe <- function () { print ( \'path ' . $c->session_path('LUNBIO00000000000001') . ' on port 0\') }',
 "if ( file.exists('.RData')) { load('.RData') }",
 
	'server <- function(){',
	'  while(TRUE){',
	'        if ( file.exists(InFiLe) ) {',
	'                while ( file.exists( LoCkFiLe ) ) {',
	'                        Sys.sleep( 2 )',
	'                }',
	'                system( paste(\'cat\', InFiLe, \'>>\', LoGfIlE ))',
	'                tFilE <- file(LoGfIlE,\'a\')',
	'                sink(tFilE, type = \'output\')',
	'                sink(tFilE, type = \'message\')',
	'                try ( { source( InFiLe )} )',
	'                sink(type = \'output\')',
	'                sink(type = \'message\')',
	'                close(tFilE)',
	'                file.remove( InFiLe )',
	'        }',
	'        Sys.sleep(2)',
	'  }',
	'}',
	'server()'
];


is_deeply( $value, $exp, "server script file contents" );

my $cmd =
    "png( file='test.png', width=400, height=400)\nplot(1:10,1:10)\ndev.off()"
  . "\nSys.sleep(2)";

$OBJ->send_2_R( $c, 'LUNBIO00000000000001', $cmd )
  ;    ## the file will 20sec not be removed!

ok( -f $c->model('Rinterface')->{'path'} . "/0.input.R", "the server input file exists" );

open( IN, "<" . $c->model('Rinterface')->{'path'} . "/0.input.R" )
  or die "I could not open the R input file\n";
$value = [ map { chomp; $_ } <IN> ];

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
$exp = [ split( "\n", $cmd ) ];

is_deeply( $value, $exp, "R input file as expected" );
close(IN);

sleep(5);

ok( @{ &is_running(0) } > 2, "server 0 is still running" );


ok(
	-f $c->session_path("LUNBIO00000000000001") . "output/test.png",
	"output figure was created '"
	  . $c->session_path("LUNBIO00000000000001")
	  . "output/test.png'"
);

ok(
	-f $c->session_path("LUNBIO00000000000001")
	  . 'scripts/test-use_automatic_commands.R',
	"the automatic R log file"
);

&file_2_value( $c->session_path("LUNBIO00000000000001")
	  . 'scripts/test-use_automatic_commands.R' );

#print "\$exp = " . root->print_perl_var_def($value) . ";\n";
#unshift( @$exp,	'setwd( \'' . $c->session_path('LUNBIO00000000000001') . 'LUNBIO00000000000001/output/\' )' );

is_deeply( $value, $exp, "The automatic log file contents" );

$OBJ->send_2_R( $c, 'LUNBIO00000000000001',
	"print('I can capture the R output messages')" );

ok( @{ &is_running(0) } > 2, "server 0 started and running" );

$c->model('Rinterface')->DESTROY();

ok( @{ &is_running(0) } == 2, "server 0 has been stopped" );

ok( !-f $c->session_path('LUNBIO00000000000001') . "0.input.R", "the R input has been removed" );

&file_2_value( $c->session_path("LUNBIO00000000000001")
	  . 'scripts/test-use_automatic_commands.R' );
push( @$exp,
	"print('I can capture the R output messages')",
	"[1] \"I can capture the R output messages\"",
	"q('yes')",
	"> proc.time()",
);
pop(@$value)
  ;    ## get rid of the variable proc time line "  0.208   0.016  11.242 "
pop(@$value)
  ; ## and get rid of the '   user  system elapsed ' as this is language specififc and therefore prone to error.
is_deeply( $value, $exp,
	"The automatic log file contents after server is shut down" );

#$c->model('Rinterface')->DESTROY();

done_testing();

sub is_running {
	my ($port) = @_;
	$port = 6011 unless ( defined $port );
	open( IN, "ps -Af | grep server_$port.R |" )
	  or die "could not start pipe\n$!\n";
	my @in = <IN>;
	close(IN);
	return \@in;
}

sub file_2_value {
	my ($file) = @_;
	open( IN, "<" . $file ) or die "I could not open the file '$file'\n$!\n";
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
			'root' => "$FindBin::Bin" . "/data/Output/Project",
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
	my ($self, $projectName) = @_;
	
	if ( defined $projectName ){
		$self->session->{'path'} = $self->config->{'root'} ."/". $projectName ."/";
		unless ( -d $self->session->{'path'} ) {
			system("mkdir -p $self->session->{'path'}");
			map { mkdir ($self->session->{'path'}."/".$_) unless( -d $self->session->{'path'}.$_) } 'data', 'scripts', 'output';
		}
		return $self->session->{'path'};
	}
	Carp::confess ( "Lib change session_path MUST get the projectName ($self, $projectName)!\n");
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
		  stefans_libs::RInterface->new( { path => "$FindBin::Bin" .  "/data/Output/Project"} );
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
