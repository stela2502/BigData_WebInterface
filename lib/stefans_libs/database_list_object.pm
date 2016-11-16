package stefans_libs::database_list_object;

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
	bless $self, $class if ( $class eq "stefans_libs::database_list_object" );

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

sub get_formdef_array {
	my ( $self, $downstream ) = @_;
	## first I need to get a list of id;unique combinations.
	my $hash         = $self->{'db_object'}->get_list_target_id_unique_hash();
	my $pre_selected = {};
	unless ( defined $self->{'database_id'} ) {
		$self->{ @{ $self->{'exported_column_names'} }[0] } = {}
		  unless (
			defined $self->{ @{ $self->{'exported_column_names'} }[0] } );
	}
	## So now I need to create the formdef entry!
	unless (
		ref( $self->{ @{ $self->{'exported_column_names'} }[0] } ) eq "HASH" )
	{

		Carp::confess(
			    "Big issue here - I expect a damn hash here not '"
			  . $self->{ @{ $self->{'exported_column_names'} }[0] }
			  . "' (for key \$self ->{ '"
			  . @{ $self->{'exported_column_names'} }[0]
			  . "' } )\n"
			  . root::get_hashEntries_as_string(
				$self,
				3, "the data structure" )
		);
	}
	my @variables = (
		{
			'name'     => @{ $self->{'exported_column_names'} }[0],
			'options'  => $hash,
			'multiple' => 1,
			'value' =>
			  [ keys %{ $self->{ @{ $self->{'exported_column_names'} }[0] } } ]
		}
	);

	#push ( @variables, 'Now we '.ref($self)." add our downstream variables:");
	my @temp = $self->get_downstream_formdef_arrays($downstream);
	return (@variables) unless ( defined $temp[0] );
	push( @variables, @temp ) if ( $temp[0] != 1 );

#Carp::confess ( root::print_hashEntries( {'variables' => \@variables, 'self' => $self} ,6, "Where are the values from the dataset??" ) );
#push ( @variables, 'Now we '.ref($self)." have added our values!");
	return (@variables);
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

=head2 AsInfo ()

get the values of the object as hash

=cut

sub AsInfo {
	my ($self) = @_;
	my $value = @{ $self->{'exported_column_names'} }[0];
	unless ( defined $self->{$value} ) {
		## OK I hope we have an issue with the _id at the end of my variable name!
		$value =~ s/_id$//;
	}
	my $dataset =
	  {     @{ $self->{'exported_column_names'} }[0] => "'"
		  . join( "', '", values( %{ $self->{'selected'} } ) )
		  . "'" };
	$self->getInfos_from_dowmnstream_objects($dataset);
	## here one can add any linked objects!
	return $dataset;
}

=head2 link_to_id ($id)

Get all internal variable from the database from an ID.

=cut

sub link_to_id {
	my ( $self, $id ) = @_;
	if ( $id == 0 ) {
		$self->{ @{ $self->{'exported_column_names'} }[0] } = {};

#		Carp::confess ( "you tried to link to the id 0 - that results in this temporary error!\n");
		return 1;
	}
	my ( $dataset, $var_name );

	$self->{ @{ $self->{'exported_column_names'} }[0] } =
	  $self->{'db_object'}->get_list_target_id_unique_hash($id);
	Carp::confess(
		root::get_hashEntries_as_string(
			$self,
			2,
"we got the id $id but I got no value from the database (\$self->{@{ $self->{'exported_column_names'} }[0]} is undefined)!\n"
. root::print_hashEntries(  [@{$self->{'db_object'}->{'data_handler'}->{'otherTable'}->{'UNIQUE_KEY'}}], 3, "This is the UNIQUE hash of the target table:")
		)
	  )
	  unless (
		scalar( keys %{ $self->{ @{ $self->{'exported_column_names'} }[0] } } )
		> 0 );
	$self->{'database_id'} = $id;
	$self->link_all_downstream_objects($dataset);
	$self->{'type'} = uc( $self->{'type'} ) if ( defined $self->{'type'} );
	return 1;
}

=head2 process_my_values ($dataset)

This function will check whether any variables between the internal hash and the $dataset
have changed and update the database accordingly.

=cut

sub process_my_values {
	my ( $self, $dataset ) = @_;
	Carp::croak(
"You have probably have used the wroing function - did you want to get id '$self->{'database_id'}'\n"
		  . root::get_hashEntries_as_string(
			$dataset,
			3,
			"If you see a hash information below you might have an error here!"
		  )
	) if ( $self->{'debug'} );
	return $self->{'database_id'};
}

sub __process_my_values {
	my ( $self, $dataset ) = @_;
	Carp::cluck(
"Hope you get what you want here - did you want to get id '$self->{'database_id'}'\n"
		  . root::get_hashEntries_as_string(
			$dataset,
			3,
			"If you see a hash information below you migt have an error here!"
		  )
	) if ( $self->{'debug'} );
	my ( $update_dataset, $other_id, $changed );
	$changed = 0;
	my @temp = $self->__get_my_values($dataset);

#Carp::confess ( root::get_hashEntries_as_string ( {'dataset'=> $dataset, 'values' => \@temp} , 3 , "the dataset to update the list object ".ref($self) ));# if ( @temp == 1);

	my $temp = '';

	if ( defined $self->{'database_id'} ) {

#$temp = "Updated the list using the list_id $self->{'database_id'} and the values ".join(" ", @temp)."\n" .$temp;
		$self->{'db_object'}->UpdateList(
			{ 'list_id' => $self->{'database_id'}, 'other_ids' => \@temp } );
	}
	else {
		$self->{'database_id'} = $self->{'db_object'}->readLatestID() + 1;

#Carp::confess ( root::get_hashEntries_as_string ( {'list_id' => $self->{'database_id'}, 'other_ids' => [$self->__get_my_values($dataset)] } , 3 ,  "I would update the list ".ref($self->{'db_object'}). " using this dataset:" ));
		$self->{'db_object'}->UpdateList(
			{ 'list_id' => $self->{'database_id'}, 'other_ids' => \@temp } );
		$temp =
"I have created a new list list using the list_id $self->{'database_id'} and the values "
		  . join( " ", @temp ) . "\n"
		  . $temp;
	}
	$self->link_to_id( $self->{'database_id'} );

	#	warn root::get_hashEntries_as_string( $self, 2,
	#		"Damn it - I created a new database_id - WHY??" )
	#	  if ( $temp =~ m/\w/ );
	return $self->{'database_id'};
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
