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
	$self->__check_user($c);
	$self->__user_has_access( $c, $projectName );
	
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
			'cols'     => 120,
			'rows'     => 30,
			'value'    => '',
			'required' => 1,
			'jsclick' =>  "hljs.highlightAuto(this.value)",
		}
	);
	$c->form->submit( ['Send to R'] );
	foreach ( @{ $self->{'form_array'} } ) {
		$c->form->field( %{$_} );
	}

	if ( $c->form->submitted() && $c->form->validate() ) {
		my $dataset = $self->__process_returned_form($c, $projectName);
		$c->model('Project')->send_2_R( $c, $projectName, $dataset->{'input'} );
		sleep(3);    ## to allow the R process to work a little
		if ($c->form->submitted() eq 'Close session') {
			$c->model('Project')->{''}
		}
		$c->res->redirect(
			$c->uri_for(
				"/rcontroll/index/$projectName/"
			)
		);
		$c->detach();
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
	$c->stash->{'outfiles'} =  data_table->new();
	$c->stash->{'outfiles'} -> add_column ( 'outfiles' , grep /^\w/, readdir(DIR) );
	$c->stash->{'outfiles'} -> HTML_modification_for_column ({'column_name' => 'outfiles', 'colsub' => 
		sub {
			my ( $self, $value, $this_hash, $type ) = @_;
			if ( $type eq "td" ){
				return "<$type><a href='".$c->uri_for("/files/index").$c->session->{'active_projects'}->{$projectName}->{'outpath'}."/$value'>$value</a></$type>";
			}else {
				return "<$type>$value</$type>";
			}
		} });
	$c->stash->{'outfiles'} = $c->stash->{'outfiles'}->GetAsHTML();
	closedir(DIR);

	#$c->form->type('TT2');
	#$c->form->template( $c->config->{'root'} . 'src' . '/form/analysis.tt2' );
	$self->file_upload($c, $projectName );
	$c->stash->{'body_extensions'} = 'onload="moveCaretToEnd(document.getElementById(\'rconsole\'))"';
	$self->Script( $c,
		  '<script type="text/javascript" src="'
		  . $c->uri_for('/scripts/highlight.pack.js')
		  . '"></script>' . "\n" );
	$c->stash->{'uploadPath'} = "/files/upload/$projectName";
	$c->stash->{'template'} = 'Rcontroller.tt2';
	$c->form->submit( ['Send to R', 'Close session'] );

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
