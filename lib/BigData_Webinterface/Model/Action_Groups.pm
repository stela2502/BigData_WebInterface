package BigData_Webinterface::Model::Action_Groups;

use strict;
use warnings;
use parent 'Catalyst::Model';
use stefans_libs::database::scientistTable::action_groups;

sub new {
	my ( $app,  $c, $hash ) = @_;
	return action_groups->new( $hash->{'dbh'} );
}

=head1 NAME

Genexpress_catalist::Model::LabBook - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Stefan Lang

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;