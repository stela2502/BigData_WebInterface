package BigData_Webinterface::Model::ACL;

use strict;
use warnings;
use parent 'Catalyst::Model';

use stefans_libs::database::scientistTable;


sub new {
	my ( $app, $c, $hash ) = @_;
	#Carp::confess ( root::get_hashEntries_as_string( {'app' => $app, 'c' => $c,'args' => [@arguments] },3, 'the variables gotten and where it was called the first time') );
	return scientistTable->new($hash->{'dbh'});
}

=head1 NAME

Genexpress_catalist::Model::jobTable - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Stefan Lang

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;