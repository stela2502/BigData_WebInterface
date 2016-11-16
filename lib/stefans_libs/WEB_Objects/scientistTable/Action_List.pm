package WEB_Objects_scientist_table_Action_List;

#  Copyright (C) 2011-10-19 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use stefans_libs::database_list_object;

use base 'stefans_libs::database_list_object';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME



=head1 DESCRIPTION



=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the .

=cut

sub new {

	my ( $class, $db_object ) = @_;

	Carp::confess(
		"I need a action_group_list object at start up, not (" . ref($db_object) . ")!" )
	  unless ( ref($db_object) eq "action_group_list" );
	my ($self);

	$self = {
		'db_object'             => $db_object,
		'database_id'           => undef,
		'exported_column_names' => [ 'action_gr_id', ]
		,    ## the important database columns
		'description'   => undef,
		'other_objects' => [],
	};

	bless $self, $class
	  if ( $class eq "WEB_Objects_scientist_table_Action_List" );

	return $self;

}

sub getInfos_from_dowmnstream_objects {   ## here we have no downstream objects!
	my ( $self, $dataset ) = @_;

	return $dataset;
}

sub link_all_downstream_objects {
	my ( $self, $dataset ) = @_;

	return $dataset;
}

sub get_downstream_formdef_arrays {
	my ( $self, $form_definition_hash ) = @_;
	my ( @temp, @values, $error );

	return @values;
}
1;
