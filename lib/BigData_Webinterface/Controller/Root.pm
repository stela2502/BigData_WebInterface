package BigData_Webinterface::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

BigData_Webinterface::Controller::Root - Root Controller for BigData_Webinterface

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

	my $path = $c->config->{'root'} . "/tmp/";
	$c->model('Menu')->Reinit();

	unless ( defined $c->session->{'known'} ) {
		$c->session->{'known'} = 0;
	}
	elsif ( $c->session->{'known'} == 0 ) {
		$c->session->{'known'} = 1;
	}

   #Carp::confess( "find ".$path." -maxdepth 1 -mtime +1 -exec rm -Rf {} \\;" );
   #system( "find " . $path . " -maxdepth 1 -mtime +1 -exec rm -Rf {} \\;" );
	$c->stash->{'news'} = [
		'2016 11 11:', "The development of the BigData Webinterface has started. Aim - to create a server similar to SCExV, but with a constant link one R session per user.",
	];

	## this position can be used to upload the files!
	$c->stash->{'uploadPage'} = $c->uri_for("/files/upload/");
	$c->stash->{'template'}   = 'start.tt2';
	
    # Hello World
 #   $c->response->body( $c->welcome_message );
}
#sub login : Local: Form : Does('RequireSSL')  {
sub login : Local: Form : Does('NoSSL')  {
	my ( $self, $c ) = @_;
	$c->cookie_check();
	$c->stash->{'template'} = 'login.tt2';
	$self->{'form_array'} = [];
	
	push(
		@{ $self->{'form_array'} },
		{
			'comment' => 'username',
			'name'    => 'username',
			'required' => 1,
		}
	);
	push(
		@{ $self->{'form_array'} },
		{
			'comment' => 'password',
			'name'    => 'password',
			'type' => 'password',
			'required' => 1,
		}
	);
	foreach ( @{ $self->{'form_array'} } ) {
		$c->form->field( %{$_} );
	}
	unless ( $c->config->{'deployed'}) {
		$c->user(
			stefans_libs_database_scientistTable_CatalystUser->new('med-sal') );
		$c->session->{'user'} = 'med-sal' ;
		$c->res->redirect( $c->uri_for('/') );
		$c->detach();
	}
	return unless ( $c->form->submitted() && $c->form->validate() );

	if (
		$c->model('ACL')->check_pw(
			$c,
			$c->form->field('username'),
			$c->_hash_pw( $c->form->field('username'), $c->form->field('password') )
		)
	  )
	{
		$c->session->{'port'} =  $c->model('Rinterface') -> port_4_user( $c->session->{'user'} );
		$c->stash->{'message'} = 'Logged in successfully.';

		#Carp::confess ( "I have the user ".$c->user."\n");
		$c->res->redirect( $c->uri_for('/') );
		$c->detach();
	}
	$c->res->redirect( $c->uri_for('/access_denied/user unknown') );
	$c->detach();
}

sub logout : Local {
	my ( $self, $c ) = @_;
	$c->model('Rinterface')->shut_down_server ( $c->session->{'port'} );
	
	foreach ( keys %{ $c->session() } ) {
		$c->session->{$_} = undef;
	}

#	$c->model('Mail_System')->log_out( $c->user() )
#	  if ( defined $c->model('Mail_System') );
	$c->logout();
	$c->flash->{'message'} = 'Logged out.';
	$c->res->redirect( $c->uri_for() );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}


sub cookiecheck: Path {
	my ( $self, $c ) = @_;
    $c->response->body( "<p>".root->print_perl_var_def( $c->session())."</p><p>".root->print_perl_var_def( $c->user() )."</p>" );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Stefan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
