package stefans_libs::database_typed_list_object;

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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::database_object

=head1 DESCRIPTION

The base class for each database object.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::database_object.

### VAVIABLE Functions
=cut

sub new {

	my ( $class, $db_object ) = @_;

	Carp::confess(
"I need a stefans_libs_database_Contacts_<SOME_TABLE> object at start up, not ("
		  . ref($db_object)
		  . ")!" )
	  unless ( ref($db_object) eq "stefans_libs_database_<SOME TABLE>" );
	my ($self);

	$self = {
		'db_object'             => $db_object,
		'database_id'           => undef,
		'variable_name'         => undef,
		'exported_column_names' => [],         ## the important database columns
		'not mandatory fields' => { 'unimportant_field' => 1 },
		'formdef_options' => { 'select_box' => [ 'Mrs', 'Mr', 'Dr', 'Prof' ] },
		'formdef_type'      => { 'select_box' => 'select' },
		'select_box'        => undef,
		'important_field'   => undef,
		'unimportant_field' => undef,
	};
	Carp::confess(
" Sorry, I am an interface - you need to create a subclass using this as parent!"
	);
	bless $self, $class
	  if ( $class eq "stefans_libs::database_typed_list_object" );

	return $self;

}

=head2 getInfos_from_dowmnstream_objects ($dataset)

this function has to be defined in the subclass. It should stuff all values 
from the downstream objects into the dataset.

=cut

sub getInfos_from_dowmnstream_objects {
	my ( $self, $dataset ) = @_;
	Carp::confess( "You need to overload this function in the sublcass "
		  . ref($self)
		  . "!" );
}

=head2 get_downstream_formdef_arrays ($types_definition_hash)

This function is called by get_formdef_array and is supposed to define all downstream objects.

=cut

sub get_downstream_formdef_arrays {
	my ( $self, $types_definition_hash ) = @_;
	Carp::confess("This function has to be implemented in each subclass!");
}

=head2 link_all_downstream_objects ( $dataset )

This function is called from link_to_id and should implement the storing and calling for all linked data table objects.
It HAS to be implemented in each subclass!

PROBABLY STABLE functions
=cut

sub link_all_downstream_objects {
	my ( $self, $dataset ) = @_;
	Carp::confess(
"You need to implement the function link_all_downstream_objects in the class"
		  . ref($self)
		  . "!" );
}

=head get_formdef_array ( $type_definition_downstream_objects )

A list will always create ONE select box where the user can select any of the existing downstream entries.
The already selected entries will only set the multiple option to the data.
But the lables for the options will be a selection of all possible unique keys.

STABLE functions
=cut

=head2 get_formdef_array ( list of email types )

This function will return a list of possible E-Mail options that can be processed into a online formular
Comming from this formulare the values can also be placed into the database.

=cut

sub get_formdef_array {
	my ( $self, @args ) = @_;
	my @values;
	@args = @{ $self->{'default_types'} } unless ( defined $args[0] );
	foreach my $type (@args) {
		foreach my $variable_name ( @{ $self->{'exported_column_names'} } ) {
			$self->{$variable_name}->{$type} = ''
			  unless ( defined $self->{$variable_name}->{$type} );
			my $hash = {
				'value'    => $self->{$variable_name}->{$type},
				'requires' => '0',
				'name'     => "$type" . "_$variable_name",
				'label'    => "$type $variable_name",
			};
			$hash->{'type'} = $self->{'formdef_type'}
			  if ( defined $self->{'formdef_type'} );
			push( @values, $hash );
		}
	}
	my @temp = $self->get_downstream_formdef_arrays();
	return (@values) unless ( defined $temp[0] );
	push( @values, @temp ) if ( $temp[0] != 1 );

	return @values;
}

=head2 AsHTML ()

this will create a HTML table consisting of all existant data entries.

=cut

sub AsHTML{
	my ( $self, @args ) = @_;
	@args = @{ $self->{'default_types'} } unless ( defined $args[0] );
	my $html = '<table>';
	if ( scalar( @{ $self->{'exported_column_names'} } ) == 1 ){
		foreach ( keys %{$self->{@{ $self->{'exported_column_names'} }[0]}} ){
			$html.= "<tr><td> $_ </td><td>".$self->{@{ $self->{'exported_column_names'} }[0]}->{$_}."</td></tr>\n";
		}
		$html .= "</table>\n";
		return $html;
	}
	my $data_table=data_table->new();
	$data_table -> Add_2_header( "Type" );
	my $datasets;
	foreach ( @{ $self->{'exported_column_names'} } ){
		$data_table -> Add_2_Header ( $_ );
		foreach my $type ( keys %{$self->{$_}} ){
			$datasets->{$type } = { 'Type' => $type } unless ( defined $datasets->{$type } );
			$datasets->{$type }->{$_} = $self->{$_}->{$type};
		}
	}
	foreach ( values %$datasets ){
		$data_table->AddDataset( $_ );
	}
	return "<p> this data portion was exported using the data_table object!</p>".$data_table->AsHTML();
}

=head2 AsInfo ()

get the values of the object as hash

=cut

sub AsInfo {
	my ( $self ) = @_;
	my $hash;
	foreach my $variable_name(  @{ $self->{'exported_column_names'} }  ){
		foreach my $type ( keys%{$self->{$variable_name}} ){
			$hash->{uc($type)} = {} unless ( defined $hash->{$type});
			$hash->{uc($type)}->{$variable_name} = $self->{$variable_name}->{$type};
		}
	}
	return $hash;
}

=head2 create_downstream_obj ( { 
	'var_name' => " ", 
	'db_obj' => " ", 
	'type' => " ", 
	'list_id' => " ", 
	'db_entry_obj' => " " ,
	'column_name' => " ",
})

This function will create a db_entry object and stuff it into the own reference 'var_name'.
But only if the entry is not existing!

The data structures created are:
$self->{'var_name'} ->{ 'type' } = 'db_entry_obj' ->new ('db_obj');
$self->{'other_objects'} will get this new db_entry object.
In case the db_obj is a basic_list, then the other_table object will be used, but
the $self->{'list_ids'}->{ref(other_table)} = { 'id' => 0 || list_id, 'list_table' =>'db_obj' }
data structure will also be created.
=cut

sub create_downstream_obj {
	my ( $self, $hash ) = @_;
	my $error = '';
	$error .=
"I can not crreate a downstream object without knowing where to store that (missing the 'var_name' key)\n"
	  unless ( defined $hash->{'var_name'} );
	$error .=
	  "I will not be able to create a db_entry_obj (missing the 'db_obj' key)\n"
	  unless ( ref( $hash->{'db_obj'} ) =~ m/database/ );
	$error .=
"I will not be able to create a db_entry_obj (missing the 'db_entry_obj' key )\n"
	  unless ( defined $hash->{'db_entry_obj'} );
	$error .= "I expect to find a 'type' key value pair!\n"
	  unless ( defined $hash->{'type'} );
	$hash->{'list_id'} = 0 unless ( defined $hash->{'list_id'} );
	if ( defined $hash->{'db_obj'}->{'data_handler'}->{'otherTable'} ) {

		unless ( $hash->{'use_this_db_obj'} ) {
			$self->{ $hash->{'var_name'} }->{ $hash->{'type'} } =
			  $hash->{'db_entry_obj'}
			  ->new( $hash->{'db_obj'}->{'data_handler'}->{'otherTable'} );
		}
		else {
			$self->{ $hash->{'var_name'} }->{ $hash->{'type'} } =
			  $hash->{'db_entry_obj'};
		}
		push(
			@{ $self->{'other_objects'} },
			$self->{ $hash->{'var_name'} }->{ $hash->{'type'} }
		);
		$self->{'list_ids'}
		  ->{ ref( $self->{ $hash->{'var_name'} }->{ $hash->{'type'} } ) } = {
			'list_id'     => $hash->{'list_id'},
			'list_obj'    => $hash->{'db_obj'},
			'column_name' => $hash->{'column_name'},
		  };
	}
	else {
		unless ( $hash->{'use_this_db_obj'} ) {
			$self->{ $hash->{'var_name'} }->{ $hash->{'type'} } =
			  $hash->{'db_entry_obj'}->new( $hash->{'db_obj'} );
		}
		else {
			$self->{ $hash->{'var_name'} }->{ $hash->{'type'} } =
			  $hash->{'db_entry_obj'};
		}
	}
	$self->{ $hash->{'var_name'} }->{ $hash->{'type'} }->{'type'} =
	  $hash->{'type'};
	return $self->{ $hash->{'var_name'} }->{ $hash->{'type'} };
}


=head2 link_to_id ($id)

Get all internal variable from the database from an ID.

=cut

sub link_to_id {
	my ( $self, $id ) = @_;
	return 1 unless ( defined $id );
	if ( $id == 0 ) {
		return 1;
	}
	my ( $dataset, $var_name, $hash );

	$dataset = $self->{'db_object'}->get_data_table_4_search(
		{
			'search_columns' => [
				$self->{'db_object'}->{'data_handler'}->{'otherTable'}
				  ->TableName() . '.id',
				'type',
				@{ $self->{'exported_column_names'} }
			],
			'where' => [ [ 'list_id', '=', 'my_value' ] ],
		},
		$id
	);
	#print ref($self)
	#  . "->link_to_id() did use the sql statemen: $self->{'db_object'}->{'complex_search'}\n";

	#$self->{ @{ $self->{'exported_column_names'} }[0] } = {};
	for ( my $i = 0 ; $i < $dataset->Lines ; $i++ ) {
		$hash = $dataset->get_line_asHash($i);
		#print root::get_hashEntries_as_string( $hash, 3, "a return hash ($i)" );

#$self->{ @{ $self->{'exported_column_names'} }[0] } -> { $hash->{$self->{'data_handler'}->{'otherTable'}->TableName().'.id'} } = $hash->{'type'}. " ". $hash->{'number'};
		foreach ( @{ $self->{'exported_column_names'} } ) {
			$self->{$_}->{ uc( $hash->{'type'} ) } = $hash->{$_};
		}
	}
	$self->{'database_id'} = $id;
	$self->link_all_downstream_objects($dataset);
	return 1;
}

sub add_to_list {
	my ( $self, $id, $other_ids ) = @_;
	return $self->{'db_object'}
	  ->UpdateList( { 'list_id' => $id, 'other_ids' => $other_ids } );
}

=head2 process_my_values ($dataset)

This function will check whether any variables between the internal hash and the $dataset
have changed and update the database accordingly.

=cut

sub process_my_values {
	my ( $self, $dataset ) = @_;
	my ( $already_added_2_list, @database_ids, $id, $i, $datasets );

	unless ( defined $self->{'database_id'} ) {
		$self->{'database_id'} = $self->{'db_object'}->readLatestID() + 1;
	}
	$i = 0;
	## parse my variables from the dataset
	foreach my $key ( keys %$dataset ) {
		foreach my $variable_name ( @{ $self->{'exported_column_names'} } ) {
			if ( $key =~ m/^([ABCDEFGHIJKLMNOPQRSTUYVWX]+)_$variable_name/ ) {
				$datasets->{$1} = { 'type' => $1, }
				  unless ( defined $datasets->{$1} );
				$datasets->{$1}->{$variable_name} = $dataset->{$key};

#			Carp::confess ( print root::get_hashEntries_as_string ({'type' => $1 , 'email' => $dataset->{$key} }  , 3 , "I have not gotten a value for the dataset!")) unless ( defined $id);

			}
		}
	}
	## put my table lines into the database
	foreach ( values %$datasets ) {
		$id = $self->Add_the_dataset($_);
		$database_ids[ $i++ ] = $id unless ( $id == -1 );
	}

	shift @database_ids unless ( $database_ids[0] =~ m/\d/ );
	if ( defined $database_ids[0] ) {

		#print "The scalar for the new ids is " . scalar(@database_ids) . "\n";
		#print "I got the IDs '" . join( "', '", @database_ids ) . "'\n";
		$self->add_to_list( $self->{'database_id'}, \@database_ids );
	}

	return $self->{'database_id'};
}

=head2 Add_the_dataset ($dataset)

This function will do some tests and add the dataset to the data containing table.

Check whether the number has been added to the system
Check whether the number was previousely known to this object

It will return the ID for the data containing table, that can be added to the list table.

=cut

sub Add_the_dataset {
	my ( $self, $dataset ) = @_;
	my ( $id, $update, $add, $check, $useless_entry, $empty_entry );
	foreach my $variable_name ( @{ $self->{'exported_column_names'} } ) {
		if ( $dataset->{$variable_name} eq "" ){
			$empty_entry = 1;
		}
		if ( $dataset->{$variable_name} =~m/^\s+$/ ){
			$empty_entry = 1;
		}
		if ( defined $self->{$variable_name}->{ $dataset->{'type'} } ) {
			if ( $self->{$variable_name}->{ $dataset->{'type'} } eq
				$dataset->{$variable_name} )
			{
				## OK this is simple - the data has already been added to the database.
				## And this object is already linked against that enry!
				$check =
				  $self->{'db_object'}->{'data_handler'}->{'otherTable'}
				  ->_return_unique_ID_for_dataset($dataset)
				  ;   ## no action needed, but I need the ID in the list update!
			}
			elsif ( $self->{$variable_name}->{ $dataset->{'type'} } =~ m/\w/ ) {
				## I will just update the old entry!
				$useless_entry = 1 if ( $dataset->{$variable_name} eq "" );
				$update = 1;
			}
			else {
				$self->{$variable_name}->{ $dataset->{'type'} } =
				  $dataset->{$variable_name};
				$add = 1;
			}
		}
		else {
			unless ( $dataset->{$variable_name} =~m/\w/ ){
				next;
			}
			if ( defined $check ) {
				$id = $check;
			}
			else {
				$id =
				  $self->{'db_object'}->{'data_handler'}->{'otherTable'}
				  ->_return_unique_ID_for_dataset($dataset);
			}
			if ( defined $id ) {
				## OK the system knows the mail address!
				$self->{$variable_name}->{ uc( $dataset->{'type'} ) } =
				  $dataset->{$variable_name};
			}
			else {
				$self->{$variable_name}->{ uc( $dataset->{'type'} ) } =
				  $dataset->{$variable_name};
				$add = 1;
			}
		}
	}

#print root::get_hashEntries_as_string( $dataset , 3 , "I have gotten the values useless_entry = '$useless_entry', check = '$check', add = '$add' and update = '$update'\n" );
	if ($useless_entry) {

		#print "Useless entry!\n";
		return -1;
	}
	elsif ($add) {

		#print "ADD\n";
		$dataset->{'type'} = uc($dataset->{'type'});
		foreach ( @{ $self->{'exported_column_names'} } ) {
			$self->{$_}->{ uc( $dataset->{'type'} ) } = $dataset->{$_};
		}
		return $self->{'db_object'}->{'data_handler'}->{'otherTable'}
		  ->AddDataset($dataset);
	}
	elsif ($check) {

		#print "only a check!\n";
		return $check;
	}
	elsif ($update) {
		my $old_dataset;
		foreach ( @{ $self->{'exported_column_names'} } ) {
			$old_dataset->{$_} = $self->{$_}->{ uc( $dataset->{'type'} ) };
		}
		$dataset->{'type'} = uc($dataset->{'type'});
		$old_dataset->{'type'} = uc($old_dataset->{'type'});
		$dataset->{'id'} =
		  $self->{'db_object'}->{'data_handler'}->{'otherTable'}
		  ->_return_unique_ID_for_dataset($old_dataset);
		  
		foreach ( @{ $self->{'exported_column_names'} } ) {
			$self->{$_}->{ uc( $dataset->{'type'} ) } = $dataset->{$_};
		}
		unless ( defined $dataset->{'id'} ) {
			warn root::get_hashEntries_as_string( $old_dataset  , 3 , 
"I processed the type $dataset->{'type'} and I could not get a id for the search:\n'"
			  . $self->{'db_object'}->{'data_handler'}->{'otherTable'}
			  ->{'complex_search'} 
			  . "\nbased on the dataset" ) ;
			return $self->{'db_object'}->{'data_handler'}->{'otherTable'}
		  		->AddDataset( $dataset );
		  	## Now I need to add the id to my table - or?
		}
		else {
			return $self->{'db_object'}->{'data_handler'}->{'otherTable'}
		  ->UpdateDataset( $dataset );
		}
		#print "UPDATE\n";
		
		
	}
	elsif ($empty_entry ) {
		return -1;
	}
	## probably OK?
	return $self->{'db_object'}->{'data_handler'}->{'otherTable'}
				  ->_return_unique_ID_for_dataset($dataset)
				  ;
	Carp::confess ( ref($self)."\nyou should never rech this part!\n". root::get_hashEntries_as_string( $dataset , 3 , "I have gotten the values useless_entry = '$useless_entry', check = '$check', add = '$add' and update = '$update'" ));
}

sub touch_master {
	my ( $self, $dataset ) = @_;
	return 1;
}

=head2 __get_my_values ( $dataset )

In case you might get the wrong names from the web server, you can change them in this function.
But per default it will remove all values from teh hash, that are already stored in tjis object.
The asumption is, that the object can only be filled with values from the databse.
Keep it that way!

=cut

sub __get_my_values {
	my ( $self, $dataset ) = @_;
	## OK - you want a new dataset without the damn types - OK
	## I only need to handle one array of values!
	my $value = @{ $self->{'exported_column_names'} }[0];
	unless ( defined $dataset->{$value} ) {
		## OK I hope we have an issue with the _id at the end of my variable name!
		$value =~ s/_id$//;
	}
	unless ( ref( $dataset->{$value} ) eq "ARRAY" ) {
		return $dataset->{$value};
	}
	return @{ $dataset->{$value} };
}

1;
