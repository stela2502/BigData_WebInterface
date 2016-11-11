package BigData_Webinterface;
use Moose;
use namespace::autoclean;
use File::Spec;
use Catalyst::Runtime 5.80;

use FindBin;
my $plugin_path = "$FindBin::Bin";

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    Static::Simple
    Session
    Session::State::Cookie
    Session::Store::FastMmap
    ConfigLoader
    Static::Simple
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in bigdata_webinterface.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

my @curdir = File::Spec->splitdir($plugin_path);
pop(@curdir);

__PACKAGE__->config(
	root => join("/", @curdir, 'root/' ),
    name => 'BigData_Webinterface',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
);

# Start the application
__PACKAGE__->setup();




sub session_path {
	my ($self, $session_id ) = @_;
	if ( defined $session_id ){
		return $self->config->{'root'}. "tmp/" . $session_id ."/";
	}
	my $path = $self->session->{'path'};
	
	if (defined $path){
		return $path if ( $path =~ m!/tmp/[\w\d]! && -d $path );
	}
	my $Root = '';
	$Root = $self->config->{'root'};

	#	my $root = "/var/www/html/HTPCR";
	$session_id = $self->get_session_id();
	unless ( $session_id = "[w\\d]" ) {
		$self->res->redirect( $self->uri_for("/") );
		$self->detach();
	}
	$path = $Root . "tmp/" . $self->get_session_id() . "/";
	$path = $Root . "tmp/" . $self->get_session_id() . "/" if ($path =~ m!//$! );
	unless ( -d $path ) {
		mkdir($path)
		  or Carp::confess("I could not create the session path $path\n$!\n");
		mkdir( $path . "libs/" );
		system( "cp $Root/R_lib/Tool* $path" . "libs/" );
		system( "cp $Root/R_lib/densityWebGL.html $path" . "libs/" );
		mkdir( $path . "libs/beanplot_mod/" );
		system( "cp $Root/R_lib/beanplot_mod/*.R $path" . "libs/beanplot_mod/" );
		Carp::confess(
			"cp $Root/R_lib/Tool* $path" . "libs/\n did not work: $!\n" )
		  unless ( -f $path . "libs/Tool_Pipe.R" );
	}
	$self->session->{'path'} = $path;
	return $path;
}

sub scrapbook {
	my ( $self ) = @_;
	return $self->session->{'path'}."/Scrapbook/Scrapbook.html" ;
}


sub cookie_check{
	my ( $self ) = @_;
	return 1 if ( $self->session->{'known'} == 1);
	unless ( defined $self->session->{'known'} ){
		$self->session->{'known'} = 0;
	}elsif ( $self->session->{'known'} == 0 ){
		$self->session->{'known'} = 1;
	}
	return 1;
}

=encoding utf8

=head1 NAME

BigData_Webinterface - Catalyst based application

=head1 SYNOPSIS

    script/bigdata_webinterface_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<BigData_Webinterface::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Stefan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
