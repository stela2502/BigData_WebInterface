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
		'2016 11 11:', "The development of the BigData Webinterface has started. Aim - to create a server similar to SCExV, but with a constant link to the R.",
	];

	## this position can be used to upload the files!
	$c->stash->{'uploadPage'} = $c->uri_for("/files/upload/");
	$c->stash->{'template'}   = 'start.tt2';
	
    # Hello World
 #   $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
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
