package BigData_Webinterface::Model::ScriptHelper;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

BigData_Webinterface::Model::ScriptHelper - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.


=encoding utf8

=head1 AUTHOR

Stefan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub scripts {
	my ( $self, $c, $lib ) = @_;
	return $self->{$lib} if ( defined $self->{$lib} );
	$self->{$lib} = [];
	my $path = $c->config->{'root'}. "/Rinterfaces/". $lib;
	if ( -d $path) {
		opendir( DIR, $path )
		  or Carp::confess(
			    "Internal server error - I can not access the existing dir '$path'\n$!\n" );
		foreach ( readdir(DIR )) {
			next if ( $_ =~ m/^\./);
			my $fm = root->filemap("$path/$_");
			open ( IN ,"<$path/$_");
			my $hash = {'name' => $fm->{'filename_base'}, 'script' => join("",<IN>)};
			close ( IN );
			$hash->{'script'} =~ s/"/\\"/g;
			$hash->{'script'} =~ s/\n/\\n/g;
			push( @{$self->{$lib}} , $hash);
			
		}
		closedir( DIR);
	}
	return $self->{$lib};
}

__PACKAGE__->meta->make_immutable;

1;
