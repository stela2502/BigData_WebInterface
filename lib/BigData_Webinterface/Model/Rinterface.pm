package BigData_Webinterface::Model::Rinterface;
use Moose;
use namespace::autoclean;
use stefans_libs::RInterface;
extends 'Catalyst::Model';

=head1 NAME

BigData_Webinterface::Model::Rinterface - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.


=encoding utf8

=head1 AUTHOR

Stefan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


sub new {
	my ( $app, @arguments ) = @_;
	return stefans_libs::RInterface->new();
}

__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

1;
