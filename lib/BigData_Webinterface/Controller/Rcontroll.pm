package BigData_Webinterface::Controller::Rcontroll;
use Moose;
use namespace::autoclean;

with 'BigData_Webinterface::controller';

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

BigData_Webinterface::Controller::Rcontroll - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Local : Form {
	my ( $self, $c, $projectName ) = @_;
	unless ( defined $projectName ) {
		$c->res->redirect( $c->uri_for('/projects/index') );
		$c->detach();
	}
	elsif ( !$c->model('Project')
		->register_project( $c, { 'name' => $projectName } ) )
	{
		$c->res->redirect(
			$c->uri_for(
				'/access_denied/You do not have access to project '
				  . $projectName
			)
		);
		$c->detach();
	}

	$self->{'form_array'} = [];
	push(
		@{ $self->{'form_array'} },
		{
			'comment'  => 'Script Area',
			'name'     => 'input',
			'type'     => 'textarea',
			'cols'     => 100,
			'rows'     => 30,
			'value'    => '',
			'required' => 1,
		}
	);
	$c->form->submit( ['Send to R'] );
	foreach ( @{ $self->{'form_array'} } ) {
		$c->form->field( %{$_} );
	}

	if ( $c->form->submitted() && $c->form->validate() ) {
		my $dataset = $self->__process_returned_form($c);
		$c->model('Project')->send_2_R( $c, $projectName, $dataset->{'input'} );
		sleep(3);    ## to allow the R process to work a little
	}

	## so now we should have a (one) woring R interface
	open( IN,
		"<" . $c->session->{'active_projects'}->{$projectName}->{'logfile'} )
	  or Carp::confess( "Internal error: could not open the R log file "
		  . $c->session->{'active_projects'}->{$projectName}->{'logfile'}
		  . "\n$!\n" );
	$c->stash->{'logfile'} = join( "", <IN> );
	close(IN);
	opendir( DIR,
		$c->session->{'active_projects'}->{$projectName}->{'outpath'} )
	  or Carp::confess("I can not open the outpath");
	$c->stash->{'outfiles'} = [ grep /^\w/, readdir(DIR) ];
	closedir(DIR);

	#$c->form->type('TT2');
	#$c->form->template( $c->config->{'root'} . 'src' . '/form/analysis.tt2' );
	$c->stash->{'template'} = 'Rcontroller.tt2';

#	my $exp = {
#		'R' => '1',
#		'logfile' =>
#'/home/stefan/git/BigData_WebInterface/root/tmp/1ee2cb40ce335fc4f4dd378f56f0b249d157ba15//LUNBIO00000000000001/scripts/med-sal_automatic_commands.R',
#		'outpath' =>
#'/home/stefan/git/BigData_WebInterface/root/tmp/1ee2cb40ce335fc4f4dd378f56f0b249d157ba15//LUNBIO00000000000001/output/',
#		'path' =>
#'/home/stefan/git/BigData_WebInterface/root/tmp/1ee2cb40ce335fc4f4dd378f56f0b249d157ba15//LUNBIO00000000000001/'
#	};
#
#	$c->response->body(
#		"\$exp = "
#		  . root->print_perl_var_def(
#			$c->session->{'active_projects'}->{$projectName}
#		  )
#		  . ";\n"
#	);
}

=encoding utf8

=head1 AUTHOR

Stefan Lang,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
