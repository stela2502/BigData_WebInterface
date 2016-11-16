package stefans_libs_WEB_Objects_scientistTable;

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
use stefans_libs::database_object;
use stefans_libs::WEB_Objects::scientistTable::Action_List;
use stefans_libs::WEB_Objects::scientistTable::Role_List;
use base 'stefans_libs::database_object';

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
		"I need a scientistTable object at start up, not (" . ref($db_object) . ")!" )
	  unless ( ref($db_object) eq "scientistTable" );
	my ($self);

	$self = {
		'db_object'             => $db_object,
		'database_id'           => undef,
		'exported_column_names' => [
			'username', 'name',
			'workgroup',    'position',      'email',    'pw', 'salt'
		],    ## the important database columns
		'formdef_value'  => {},
		'formdef_hidden' => {},
		'formdef_value'  => {},
		'formdef_type' =>
		  { 'action_gr_id' => 'select', 'roles_list_id' => 'select', 'pw' => 'password' , 'salt' => 'hidden' }
		,
		'username'      => undef,
		'name'          => undef,
		'workgroup'     => undef,
		'position'      => undef,
		'email'         => undef,
		'pw'            => undef,
		'other_objects' => [],
	};

	bless $self, $class
	  if ( $class eq "stefans_libs_WEB_Objects_scientistTable" );

	return $self;

}

sub MODIFY_BEFORE_PROCESS_MY_VALUES {
	my ( $self, $dataset ) = @_;
	if ( defined $dataset->{'pw'} ) {
		my $temp;
		($dataset->{'pw'}, $temp, $dataset->{'salt'} ) = $self->{'db_object'}->_hash_pw( $dataset->{'username'}, $dataset->{'pw'} );
	}
	return 1;
}
sub has_role {
	my ( $self, $role ) = @_;
	my $return = 0;
	foreach ( values %{$self->{'roles_list_id'}}){
		$return = 1 if ($_ eq $role);
	}
	return $return;
}

sub AddRole{
	my ( $self, $role_name ) = @_;
	return undef unless ( defined $role_name);
	return $self->{'db_object'} ->AddRole ( { 'username' => $self->{'username'}, 'role' => $role_name});
}

sub roles {
	my ( $self ) = @_;
	my $roles;
	foreach ( values %{$self->{'role_list_id'}}){
			$roles -> {$_} = 1;
	}
	return $roles;
}

sub getInfos_from_dowmnstream_objects {   ## here we have no downstream objects!
	my ( $self, $dataset ) = @_;
	$self->link_all_downstream_objects();
	$dataset->{action_gr}  = $self->{action_gr}->{"object"}->AsInfo();
	$dataset->{roles_list} = $self->{roles_list}->{"object"}->AsInfo();

	return $dataset;
}

sub link_all_downstream_objects {
	my ( $self, $dataset ) = @_;
	$self->{'list_objects'}->{'action_gr_id'} = $self->create_downstream_obj(
		{
			"var_name" => "action_gr",
			"db_obj" =>
			  $self->{"db_object"}->{"data_handler"}->{"action_group_list"},
			"type"         => "object",
			"list_id"      => $dataset->{"action_gr_id"},
			"db_entry_obj" => "WEB_Objects_scientist_table_Action_List",
			"column_name"  => "action_gr_id"
		}
	);
	$self->{'list_objects'}->{'roles_list_id'} =$self->create_downstream_obj(
		{
			"var_name" => "roles_list",
			"db_obj"   => $self->{"db_object"}->{"data_handler"}->{"role_list"},
			"type"     => "object",
			"list_id"  => $dataset->{"roles_list_id"},
			"db_entry_obj" => "WEB_Objects_scientist_table_Role_List",
			"column_name"  => "roles_list_id"
		}
	);

	return $dataset;
}

sub get_downstream_formdef_arrays {
	my ( $self, $form_definition_hash ) = @_;
	my ( @temp, @values, $error );
	unless ( defined $self->{action_gr}->{"object"} ){
		$self->{'list_objects'}->{'action_gr_id'} = $self->create_downstream_obj(
		{
			"var_name" => "action_gr",
			"db_obj" =>
			  $self->{"db_object"}->{"data_handler"}->{"action_group_list"},
			"type"         => "object",
			"db_entry_obj" => "WEB_Objects_scientist_table_Action_List",
			"column_name"  => "action_gr_id"
		}
	);
	}
	@temp = ( $self->{action_gr}->{"object"}->get_formdef_array() );
	push( @values, @temp );
	unless ( defined $self->{roles_list}->{"object"} ){
		$self->{'list_objects'}->{'roles_list_id'} = $self->create_downstream_obj(
		{
			"var_name" => "roles_list",
			"db_obj"   => $self->{"db_object"}->{"data_handler"}->{"role_list"},
			"type"     => "object",
			"db_entry_obj" => "WEB_Objects_scientist_table_Role_List",
			"column_name"  => "roles_list_id"
		}
	);
	}
	@temp = ( $self->{roles_list}->{"object"}->get_formdef_array() );
	push( @values, @temp );

	return @values;
}

sub get_existing_values {
	my ( $self, $form_definition_hash ) = @_;
	
	if ( $form_definition_hash->{'superuser'}) {
		my $data_table = $self-> {'db_object'} -> get_data_table_4_search( {
			'search_columns' => [ref( $self-> {'db_object'}).'.id', ref($self-> {'db_object'}).'.username'],
		});
		return { 
			'name' => 'scientist_id',
			'label' => 'select user',
			'options' => $data_table ->getAsHash ( 'scientistTable.id', 'scientistTable.username'),
			'type' => 'select'
		}
	}
	else {
		return  {
			'name' => 'scientist_id',
			'type' => 'hidden',
			'value' => $form_definition_hash->{'user_id'}
		}
	}
}

1;
