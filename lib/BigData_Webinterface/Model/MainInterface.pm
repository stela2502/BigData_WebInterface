package BigData_Webinterface::Model::MainInterface;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

BigData_Webinterface::Model::MainInterface - Catalyst Model

=head1 DESCRIPTION

This is the main interface, that takes care / will take care of path mappings and access rights.


=encoding utf8

=head1 AUTHOR

Stefan

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
