package BigData_Webinterface::Model::Project;
use Moose;
use namespace::autoclean;
use stefans_libs::database::Projects;

extends 'Catalyst::Model';

=head1 NAME

BigData_Webinterface::Model::Project - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.


=encoding utf8

=head1 AUTHOR

Stefan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub new{
	my ( $class, $c, $hash) = @_;
	my $self = {
		'projects' => stefans_libs::database::Projects->new( $hash->{'dbh'} ),
		'active' => {},
	};
	
	bless $self, $class if ( $class eq "BigData_Webinterface::Model::Project" );
	
	return $self;
}

=head3 register_project ($c, { 'name' => 'LUNBIO'.sprintf("%014", 1),  OR 'description' => "Some description" } )

giving a description will create a new project, populate it and return it.

=cut

sub user_has_access {
	my ( $self, $c, $projectName ) = @_;
	return $self->{'projects'}->user_has_access($projectName, $c->user() ) ;
}

sub register_project {
	my ( $self, $c, $hash ) = @_;
	my $projectName;
	unless ( defined $hash->{'name'} ) {
		$self->{'projects'}->_create_md5_hash ($hash );
		#Carp::confess ( "is there a md5_sum?? \$exp = " . root->print_perl_var_def( $hash ) . ";\n" );
		my $id =  $self->{'projects'}-> _select_all_for_DATAFIELD ( $hash->{'md5_sum'} , 'md5_sum' );
		if ( @$id){
			#Carp::confess ( "is there a md5_sum?? \$exp = " . root->print_perl_var_def( $id ) . ";\n");
			$projectName = @$id[0]->{'name'};
			$id = @$id[0]->{'id'};
			
		}
		else {
			$id = $self->{'projects'}->AddDataset({
				'description' => $hash->{'description'},
				'owner' => $c->model('ACL')->Get_id_for_name( $c->user() ),
				});
				$projectName = $self->{'projects'}->get_project_name_4_id( $id );
		}
		
	}else {
		if ( $self->user_has_access($c, $hash->{'name'}) ){
			$projectName = $hash->{'name'};
		}
	}
	return $self if ( $c->session->{'active_projects'} ->{$projectName} and $c->model('Rinterface') -> is_running( $c->session->{'active_projects'} ->{$projectName}->{'R'}) );
	$self->{active}->{$c->user()} ||= {};
	my $server = 
		  "## the strage var names are to not interfere with user defined variable names\n"
		  . "LoGfIlE <- '".$self->path( $c, $projectName)."scripts/".$c->user()."_automatic_commands.R'\n"
		  . "LoCkFiLe <- '##PATH##/##PORT##.input.lock'\n"
		  . "InFiLe <- '##PATH##/##PORT##.input.R'\n"
		  
		  . "setwd( '".$self->path( $c, $projectName).'output/'."' )\n"
		  . "system( paste('touch', LoGfIlE) )\n"
		  . "identifyMe <- function () { print ( 'path ".$self->path( $c, $projectName)." on port ##PORT##') }\n"
		  . "if ( file.exists('.RData')) { load('.RData') }\n"
		  
		  . "server <- function(){\n"
		  . "  while(TRUE){\n"
		 . "        if ( file.exists(InFiLe) ) {\n"
		  . "                while ( file.exists( LoCkFiLe ) ) {\n"
		  . "                        Sys.sleep( 2 )\n"
		  . "                }\n"
		  # redirect message and output to the LoGfIlE
		  . "                system( paste('cat', InFiLe, '>>', LoGfIlE ))\n"
		  . "                tFilE <- file(LoGfIlE,'a')\n"
		  . "                sink(tFilE, type = 'output')\n"
		  . "                sink(tFilE, type = 'message')\n"
		  # run the file
		  . "                try ( { source( InFiLe )} )\n"
		  # close the redirect
		  . "                sink(type = 'output')\n"
		  . "                sink(type = 'message')\n"
		  . "                close(tFilE)\n"
		  # remove the InFiLe to allow a new command sent from the web server
		  . "                file.remove( InFiLe )\n"
		  . "        }\n"
		  . "        Sys.sleep(2)\n" . "  }\n" . "}\n"
		#  . "setwd('".$self->path( $c, $projectName).'output/'."')\n"
		  . "server()\n";
		  
	$self->{active}->{$c->user()}->{$projectName} = $c->model('Rinterface') -> port_4_user( $c->user(), $projectName, $server );
	
	$c->session->{'active_projects'} ||= {};
	$c->session->{'active_projects'} ->{$projectName} = { 
		'path' => $self->path( $c, $projectName), 
		'R' => $self->{active}->{$c->user()}->{$projectName},
		'logfile' => $self->path( $c, $projectName)."scripts/".$c->user()."_automatic_commands.R",
		'outpath' => $self->path( $c, $projectName).'output/',
	};
	
	return $self;
}

sub send_2_R {
	my ( $self, $c, $projectName, $cmd ) =@_;
	my $op = $self->path( $c, $projectName)."output/";
	$cmd =~ s/##OUTPATH##/$op/g;
	#$cmd =~ s/"/\\"/g;
	my $port = $c->session->{'active_projects'} ->{$projectName}->{'R'};
	unless ( defined $port ) {
		## wow a server crash or why is the R asked for, but not in our datasets?
		$self->register_project( $c, {'name' => $projectName} );
		$port = $c->session->{'active_projects'} ->{$projectName}->{'R'};
	}
	unless ( $c->model('Rinterface') -> is_running($port)){
		$c->model('Rinterface') -> spawn_R ($port);
		$c->model('Rinterface') -> send_2_R ( "setwd( '$op' )", $port );
	}
	
	$c->model('Rinterface') -> send_2_R($cmd, $port );
	return $self;
}

sub path {
	my ( $self, $c ,$projectName ) = @_;
	my $p = $c->session_path($projectName);
	mkdir ( $p ) unless ( -d $p );
	map { mkdir ($p.$_) unless( -d $p.$_) } 'data', 'scripts', 'output';
	return $p;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
