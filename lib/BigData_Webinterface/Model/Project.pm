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

sub register_project {
	my ( $self, $c, $hash ) = @_;
	my $projectName;
	unless ( defined $hash->{'name'} ) {
		my $id = $self->{'projects'}->AddDataset({
			'description' => $hash->{'description'},
			'owner' => $c->model('ACL')->Get_id_for_name( $c->user() ),
			}
		);
		$projectName = $self->{'projects'}->get_project_name_4_id( $id );
	}else {
		if ( $self->{'projects'}->user_has_access($hash->{'name'}, $c->user() ) ){
			$projectName = $hash->{'name'};
		}
	}
	$self->{active}->{$c->user()} ||= {};
	my $server = 
		  "logfile <- '".$self->path( $c, $projectName)."scripts/".$c->user()."_automatic_commands.R'\n"
		  . "infile <- '##PATH##/##PORT##.input.R'\n"
		  . "system( 'touch logfile')\n"
		  . "server <- function(){\n"
		  . "  while(TRUE){\n"
		 . "        if ( file.exists(infile) ) {\n"
		  . "                while ( file.exists( paste(infile,'log', sep='.' ) ) ) {\n"
		  . "                        Sys.sleep( 2 )\n"
		  . "                }\n"
		  . "                system( paste('cat', infile, '>>', logfile ))\n"
		  . "                capture.output(source( infile ), file= logfile, append =T, type='output' )\n"
		  . "                file.remove( infile )\n"
		  . "        }\n"
		  . "        Sys.sleep(2)\n" . "  }\n" . "}\n"
		#  . "setwd('".$self->path( $c, $projectName).'output/'."')\n"
		  . "server()\n";
		  
	$self->{active}->{$c->user()}->{$projectName} = $c->model('Rinterface') -> port_4_user( $c->user(), $projectName, $server );
	
	$c->model('Rinterface') -> send_2_R ( "setwd( '".$self->path( $c, $projectName).'output/'."' )", $self->{active}->{$c->user()}->{$projectName} );
	$c->session->{'active_projects'} ||= {};
	$c->session->{'active_projects'} ->{$projectName} = { 
		'path' => $self->path( $c, $projectName), 
		'R' => $self->{active}->{$c->user()}->{$projectName},
	};
	
	return $self;
}

sub send_2_R {
	my ( $self, $c, $projectName, $cmd ) =@_;
	my $op = $self->path( $c, $projectName)."outpath/";
	$cmd =~ s/##OUTPATH##/$op/g;
	$c->model('Rinterface') ->send_2_R($cmd, $self->{active}->{$c->user()}->{$projectName} );
	return $self;
}

sub path {
	my ( $self, $c ,$projectName ) = @_;
	my $p = $c->session_path()."/$projectName/";
	mkdir ( $p ) unless ( -d $p );
	map { mkdir ($p.$_) unless( -d $p.$_) } 'data', 'scripts', 'output';
	return $c->session_path()."/$projectName/";
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
