package stefans_libs::database_object;

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
		'exported_column_names' => [],         ## the important database columns
		'not mandatory fields' => { 'unimportant_field' => 1 },
		'formdef_options' => { 'select_box' => [ 'Mrs', 'Mr', 'Dr', 'Prof' ] },
		'formdef_type'      => { 'select_box'    => 'select' },
		'list_objects'      => { 'variable_name' => "a WEB list object" },
		'insert_into_this_table' => '/path_to_the/instert_page',
		'select_box'        => undef,
		'important_field'   => undef,
		'unimportant_field' => undef,
	};
	Carp::confess(
" Sorry, I am an interface - you need to create a subclass using this as parent!"
	);
	bless $self, $class if ( $class eq "stefans_libs::database_object" );

	return $self;

}

=head2 getSelect_form ( $var_name, [ {'where' => [['id','=','my_value]]}, [1,14,17,23] ] )

This function call would create a select box, where you can select the id's 1,14,17,23 based on their unique string

=cut

sub getSelect_form {
	my ( $self, $variable_name, $select_statement ) = @_;
	unless ( ref ( $select_statement ) eq "ARRAY") {
		$select_statement = [ {'where' => [] } ]
	}
	@{$select_statement}[0]->{
		'search_columns'} = [
			ref( $self->{'db_object'} ) . '.id',
			map { ref( $self->{'db_object'} ) . ".$_" }
			  @{$self->{'db_object'}->{'UNIQUE_KEY'}}
		];
	@{$select_statement}[0]->{'complex_select'} = undef;
	my $data_table =
	  $self->{'db_object'}->get_data_table_4_search(@$select_statement);
	my ( @options, $id, $i );
	$i = 0;
	foreach my $line (@{$data_table->{'data'}}) {
		$id = shift(@$line);
		$options[$i] = { $id => join( " ", @$line ) };
		$i++;
	}
	## here I want to get an easy option to reach the page where I can insert all the informations for a new entry
	## the page is of cause dependant on the Controller class, but I can create a new variable to store this info in
	## $self->{'insert_into_this_table'}
	my $hash = {
		'name'     => $variable_name,
		'label'    => $variable_name,
		'required' => 1,
		'options'  => \@options
	};
	if ( defined $self->{'insert_into_this_table'} ) {
		$hash ->{'label'} = '<a class="tooltip" href="'.$self->{'insert_into_this_table'}.'"  target="_blank">'.$variable_name.
		'<span>Click this link to create a new entry</span></a>';
	}
	return $hash;
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

This function has to return Perl Formbuilder form definition hashes as an list of hashes.
The internal variables $self->{'formdef_type'} and $self->{'formdef_options'} can be used 
to change the appearance of the form elements.

STABLE functions
=cut

sub get_formdef_array {
	my ( $self, $downstream ) = @_;
	my ( @variables, $required );
	$self->{'type'} = '' unless ( defined $self->{'type'} );
	unless ( $self->{'type'} =~ m/\w/ ) {
		foreach ( @{ $self->{'exported_column_names'} } ) {
			next if ( defined $self->{'objects'}->{$_} );
			next if ( $_ eq "type" );
			$required = 1;
			$required = 0 if ( $self->{'not mandatory fields'}->{$_} );
			push(
				@variables,
				{
					'name'     => $_,
					'label'    => $_,
					'required' => $required,
					'value'    => $self->{$_}
				}
			);
			if ( defined $self->{'formdef_type'}->{$_} ) {
				$variables[ @variables - 1 ]->{'type'} =
				  $self->{'formdef_type'}->{$_};
				if ( $variables[ @variables - 1 ]->{'type'} eq "textarea" ) {
					$variables[ @variables - 1 ]->{'cols'}  = 60;
					$variables[ @variables - 1 ]->{'rows'}  = 10;
					$variables[ @variables - 1 ]->{'style'} =
					  "position:relative;;top:3px;";
				}
			}
			if ( defined $self->{'formdef_hidden'}->{$_} ) {
				$variables[ @variables - 1 ]->{'type'} = 'hidden';
			}
			## mess with the values
			$variables[ @variables - 1 ]->{'value'} =
			  $self->{'formdef_value'}->{$_}
			  if ( ( ! defined $variables[ @variables - 1 ]->{'value'} || $variables[ @variables - 1 ]->{'value'} eq "" )
				&& defined $self->{'formdef_value'}->{$_} );

			$variables[ @variables - 1 ]->{'options'} =
			  $self->{'formdef_options'}->{$_}
			  if ( defined $self->{'formdef_options'}->{$_} );
		}
	}
	else {
		foreach ( @{ $self->{'exported_column_names'} } ) {
			next if ( $_ eq "type" );
			$required = 1;
			$required = 0 if ( $self->{'not mandatory fields'}->{$_} );
			push(
				@variables,
				{
					'name'     => $self->{'type'} . '_' . $_,
					'label'    => $_,
					'required' => $required,
					'value'    => $self->{$_}
				}
			);
			$variables[ @variables - 1 ]->{'type'} =
			  $self->{'formdef_type'}->{$_}
			  if ( defined $self->{'formdef_type'}->{$_} );
			$variables[ @variables - 1 ]->{'value'} =
			  $self->{'formdef_value'}->{$_}
			  unless ( defined $variables[ @variables - 1 ]->{'value'} );

			$variables[ @variables - 1 ]->{'options'} =
			  $self->{'formdef_options'}->{$_}
			  if ( defined $self->{'formdef_options'}->{$_} );
		}
	}

	#push ( @variables, 'Now we '.ref($self)." add our downstream variables:");
	my @temp = $self->get_downstream_formdef_arrays($downstream);
	push( @variables, @temp ) if ( $temp[0] != 1 );

#Carp::confess ( root::print_hashEntries( {'variables' => \@variables, 'self' => $self} ,4, "Where are the values from the dataset??" ) );
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

		if ( $hash->{'db_entry_obj'}->isa('stefans_libs::database_object') ) {
			unless ( $hash->{'use_this_db_obj'} ) {
				$self->{ $hash->{'var_name'} }->{ $hash->{'type'} } =
				  $hash->{'db_entry_obj'}->new( $hash->{'db_obj'} )
				  ; ## Do I have modules that need not the list object here? ->{'data_handler'}->{'otherTable'} );
				$self->{ $hash->{'var_name'} }->{ $hash->{'type'} }
				  ->link_to_id( $hash->{'list_id'} )
				  if ( defined $hash->{'list_id'} );
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
			  ->{ ref( $self->{ $hash->{'var_name'} }->{ $hash->{'type'} } ) } =
			  {
				'list_id'     => $hash->{'list_id'},
				'list_obj'    => $hash->{'db_obj'},
				'column_name' => $hash->{'column_name'},
			  };
		}
		elsif (
			$hash->{'db_entry_obj'}->isa('stefans_libs::database_list_object') )
		{
			unless ( $hash->{'use_this_db_obj'} ) {
				$self->{ $hash->{'var_name'} }->{ $hash->{'type'} } =
				  $hash->{'db_entry_obj'}->new( $hash->{'db_obj'} );
				$self->{ $hash->{'var_name'} }->{ $hash->{'type'} }
				  ->link_to_id( $hash->{'list_id'} )
				  if ( defined $hash->{'list_id'} );
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
			  ->{ ref( $self->{ $hash->{'var_name'} }->{ $hash->{'type'} } ) } =
			  {
				'list_id'     => $hash->{'list_id'},
				'list_obj'    => $hash->{'db_obj'},
				'column_name' => $hash->{'column_name'},
			  };
		}
		elsif ( $hash->{'db_entry_obj'}
			->isa('stefans_libs::database_typed_list_object') )
		{
			$self->{ $hash->{'var_name'} }->{ $hash->{'type'} } =
			  $hash->{'db_entry_obj'}->new( $hash->{'db_obj'} );
			warn
"I try to call link_to_id on a $hash->{'var_name'} $hash->{'type'} object ($self->{ $hash->{'var_name'} }->{ $hash->{'type'} })\n";
			$self->{ $hash->{'var_name'} }->{ $hash->{'type'} }
			  ->link_to_id( $hash->{'list_id'} )
			  if ( defined $hash->{'list_id'} );
		}
		else {
			Carp::confess(
"Damn - all Web objects need to be either a 'database_list_object' or a 'database_object'\nthat is not true for this class: "
				  . $hash->{'db_entry_obj'}
				  . "\n" );
		}
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
	my $dataset = {};
	foreach ( @{ $self->{'exported_column_names'} } ) {
		$dataset->{$_} = $self->{$_};
	}
	$self->getInfos_from_dowmnstream_objects($dataset);
	## here one can add any linked objects!
	return $dataset;
}

=head2 link_to_id ($id)

Get all internal variable from the database from an ID.

=cut

sub link_to_id {
	my ( $self, $id ) = @_;
	my ( $dataset, $var_name );
	unless ( defined $id ) {
		foreach ( @{ $self->{'exported_column_names'} } ) {
			$dataset->{$_} = undef;
		}
		$self->link_all_downstream_objects($dataset);
		return $self;
	}
	$var_name = ref( $self->{'db_object'} );
	$dataset  = $self->{'db_object'}->get_data_table_4_search(
		{
			'search_columns' => ["$var_name.*"],
			'where'          => [ [ "$var_name.id", '=', 'my_value' ] ],
		},
		$id
	)->get_line_asHash(0);
	my $other_dataset;
	foreach my $key ( keys %$dataset ) {
		if ( $key =~ m/(\w+)\.(\w+)/ ) {
			$other_dataset->{$2} = $dataset->{$key};
		}
		else {
			$other_dataset->{$key} = $dataset->{$key};
		}
	}
	$dataset = $other_dataset;
	return 0 unless ( defined $dataset );
	$self->{'database_id'} = $id;
	foreach ( @{ $self->{'exported_column_names'} } ) {
		$self->{$_} = $dataset->{$_};
	}
	$self->link_all_downstream_objects($dataset);
	$self->{'type'} = uc( $self->{'type'} ) if ( defined $self->{'type'} );
	return $self;
}

=head2 process_my_values ($dataset)

This function will check whether any variables between the internal hash and the $dataset
have changed and update the database accordingly.

=cut

sub MODIFY_BEFORE_PROCESS_MY_VALUES {
	my ( $self, $dataset ) = @_;
	return 1;
}

sub process_my_values {
	my ( $self, $dataset ) = @_;
	## I need to check whether I have my own ID and whether I am already defined in the database!
	$self->MODIFY_BEFORE_PROCESS_MY_VALUES( $dataset );
	unless ( defined $self->{'database_id'} ) {
		my $temp = {};
		while ( my ( $key, $value ) = each %$dataset ) {
			if ( ref($value) eq "ARRAY" ) {
				$temp->{$key} = [@$value];
			}
			else {
				$temp->{$key} = $value;
			}
		}
		my $id = $self->{'db_object'}->_return_unique_ID_for_dataset($temp);
		if ( defined $id ) {
			$self->link_to_id($id);
		}
	}
	my ( $update_dataset, $other_id, $changed );
	$self->get_downstream_formdef_arrays();
	$changed = 0;
	$update_dataset = $self->__get_my_values($dataset);
#	warn  root::print_hashEntries( $update_dataset , 3, ref($self)." I am processing my values.\n");
	if ( defined $self->{'database_id'} ) {
		$update_dataset->{'id'} = $self->{'database_id'};
		if ( scalar( keys %$update_dataset ) > 1 ) {
			$self->{'db_object'}->UpdateDataset($update_dataset);
			$self->{'last_db_hash'} = $update_dataset;
			$changed = 1;
		}
	}
	else {
		unless ( scalar( keys %$update_dataset ) == 0 )
		{    
			foreach my $key ( %{ $self->{'list_ids'} } ) {
				$update_dataset->{ $self->{'list_ids'}->{$key}
					  ->{'column_name'} } =
				  $self->{'list_ids'}->{$key}->{'list_id'}
				  if ( defined $self->{'list_ids'}->{$key}->{'column_name'} );
			}
			$self->{'database_id'} =
			  $self->{'db_object'}->AddDataset($update_dataset);
			$self->{'last_db_hash'} = $update_dataset;
			$changed = 1;
			#Carp::confess ( "I have created a new dataset with the ID $self->{'database_id'} using this SQL:\n".$self->{'db_object'}->{'complex_search'}."\n");
		}
	}

#Carp::confess ( root::get_hashEntries_as_string ( {'other_objects' =>  $self->{'other_objects'} , 'dataset' => $dataset } , 3 , "These Object I want to give data to" ));
	foreach ( @{ $self->{'other_objects'} } ) {
		## this will add the entry to the table, but will not affect the list table!
		$other_id = $_->process_my_values($dataset);
		## Hence I have to create the list_id if it has not been defined yet.
		## A list_id is undefined if it is 0!

		if ( defined $self->{'list_ids'}->{ ref($_) } && defined $other_id ) {
			my $info = $self->{'list_ids'}->{ ref($_) };
			if ( $_->isa('database_list_object') ) {
				$info->{'list_id'} = $_->__process_my_values($dataset);
			}
			else {
				$info->{'list_id'} = $_->process_my_values($dataset);
			}
			$self->{'db_object'}->UpdateDataset(
				{
					'id' => $self->{'database_id'},
					$self->{'list_ids'}->{ ref($_) }->{'column_name'} =>
					  $info->{'list_id'}
				}
			);

#Carp::confess (  root::get_hashEntries_as_string ( {'dataset' => $dataset, 'the object' => $self->{'list_ids'}->{ ref($_) }, 'other_id' => $other_id } , 3 ,  "I would love to know what I do here!"));
		}
		elsif ( !defined $self->{'list_ids'}->{ ref($_) } ) {
			Carp::confess(
"Internal error - please define the variable \$self->{'list_ids'}->{ "
				  . ref($_)
				  . " }" );
		}
	}
	$self->process_other_values($dataset);
	$self->touch_master($dataset);
	return $self->{'database_id'};
}

sub process_other_values {
	##should normally not me necessary, only the list objects do need that!
	return 1;
}

sub touch_master {
	my ( $self, $dataset ) = @_;
	return 1;
}

=head2 __get_my_values ( $dataset )

In case you might get the wrong names from the web server, you can change them in this function.
But per default it will remove all values from the hash, that are already stored in this object.
The asumption is, that the object can only be filled with values from the database.
Keep it that way!

=cut

sub __get_my_values {
	my ( $self, $dataset ) = @_;
	## OK - you want a new dataset without the damn types - OK
	my $return = {};
	$self->{'type'} = '' unless ( defined $self->{'type'} );
	foreach ( @{ $self->{'exported_column_names'} } ) {
		$self->{$_} = '' unless ( defined $self->{$_} );
		if ( defined $dataset->{$_} ) {
			$return->{$_} = $dataset->{$_}
			  unless ( $self->{$_} eq $dataset->{$_} );
		}
		elsif ( defined $dataset->{ $self->{'type'} . "_" . $_ } ) {
			$return->{$_} = $dataset->{ $self->{'type'} . "_" . $_ };
		}
		elsif ( defined $dataset->{ $self->{'type'} . "." . $_ } ) {
			$return->{$_} = $dataset->{ $self->{'type'} . "." . $_ };
		}
		else {

			#Carp::confess("Hey! I miss the value for key $_\n");
		}
		if ( defined $return->{$_} ) {
			delete( $return->{$_} ) unless ( $return->{$_} =~ m/[\w\d]/ );
		}

	}
	foreach my $key ( keys %{ $self->{'list_objects'} } ) {
		## the list objects are tricky - they will kill the whole process if I do not get some values here!
		my @temp = $self->{'list_objects'}->{$key}->__get_my_values($dataset);
		unless ( defined $dataset->{$key} ) {
			## if I do not have a already stuffed object I will kill here!
			if ( !( defined $self->{'list_objects'}->{$key}->{'database_id'} ) )
			{
				Carp::confess(
"Sorry, but list tables MUST have values when you create an object!\n"
					  . root::get_hashEntries_as_string(
						$dataset,
						3,
						"I expected the value '$key' to be set in this dataset:"
					  )
				);
			}
		}
		## Now I expect to have a List of data here - and this list has to be updated!
		$return->{$key} =
		  $self->{'list_objects'}->{$key}->__process_my_values($dataset);

#		elsif ( $self->{'list_objects'}->{$key}->{'database_id'} != $temp[0] ) {
#			print
#"I add a connection for the variable name '$key' using the list_id '$self->{'list_objects'}->{$key}->{'database_id'}' and the id(s) ". join(" ",@temp) ."\n";
#			$return->{$key} =
#			  $self->{'list_objects'}->{$key}->__process_my_values($dataset);
#		}
#		else {
#			## OK now I got a list of ids, that the list should contain!
#			## In reallity I should not keep the system from updating the list!
#			$return->{$key} =
#			  $self->{'list_objects'}->{$key}->__process_my_values($dataset);
#			Carp::confess(
#"I have kept the system from adding a list connection for the variable name '$key' using the object $self->{'list_objects'}->{$key} and the id(s) ". join(" ",@temp) ."\n"
#			);
#		}
	}
	return $return unless ( scalar( keys %$return ) > 0 );
	$return->{'type'} = $self->{'type'}
	  if ( defined $self->{'type'} && $self->{'type'} =~ m/\w/ );
	$self->{'type'} = undef if ( !$self->{'type'} =~ m/\w/ );
	return $return;
}

1;
