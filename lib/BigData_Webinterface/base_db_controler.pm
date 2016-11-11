package BigData_Webinterface::base_db_controler;

use strict;
use warnings;
use DateTime::Format::Strptime;
use Catalyst::Controller::FormBuilder;
use base 'Catalyst::Controller::FormBuilder';

=head2 Add_add_form

Arguments: A Catalyst object and a hash containing at the minimum the value 'db_obj' 
that has to be a genexpress database model implementing a variable_table.
In addition, you may supply a 'downstream_table' variable, if you want to get a insert statement for the downstream table.
The last part is the 'redirect_on_success' variable, that should contain a relative location  in the genexpress web frontend.
If that contains a ##ID## tag, this tag will be exchanged to the newly created database ID.


=head2 __check_user ($c, $REQUIRED_ROLE)

This function cecks the rights of the users. First, whether the user is logged in.
If he/she is logged in and the function also requires an role the role is checked.

If the $REQUIRED_ROLE is an array of roles, any of the roles is sufficient to access the page.

=cut

sub __check_user {
	my ( $self, $c, $REQUIRED_ROLE, $return_0 ) = @_;
	unless ( $c->user =~ m/\w/ ) {
		$c->res->redirect('/access_denied');
		$c->detach();
	}
	if ( defined $REQUIRED_ROLE ){
		my $OK = 0;
		if ( ref($REQUIRED_ROLE) eq "ARRAY" ) {
			## OK if ANY of these roles apply I will allow the access
			foreach my $role ( @$REQUIRED_ROLE){
				$OK = 1 if ( $c->model("ACL")->user_has_role( $c->user, $role ));
			}
		}
		elsif ( $c->model("ACL")->user_has_role( $c->user, $REQUIRED_ROLE )){
			$OK = 1;
		}
		unless ( $OK ){
			return 0 if  ( $return_0  );
			$c->res->redirect('/access_denied');
			$c->detach();
		}
	}
	return 1;
}


sub Add_update_form {
	my ( $self, $c, $hash ) = @_;
	my ( $db_obj, $downstream_table, $redirect_on_success, $unique_hash,
		$oldDataset );
	$db_obj              = $hash->{'db_obj'};
	$downstream_table    = $hash->{'downstream_table'};
	$redirect_on_success = $hash->{'redirect_on_success'};
	$unique_hash         = $hash->{'unique'};

	my @form_array;
	Carp::confess(
		ref($self) . "::Add_add_form -> we do not have a \$c variable ($c)\n" )
	  unless ( ref($c) =~ m/\w/ );
	$oldDataset = $db_obj->get_data_table_4_search(
		{
			'search_columns' => [ ref($db_obj) . ".*" ],
			'where'          => [ [ ref($db_obj) . ".id", "=", "my_value" ] ]
		},
		$db_obj->_return_unique_ID_for_dataset($unique_hash)
	)->get_line_asHash(0);

	unless ( defined $oldDataset ) {
		$c->stash->{'error'} =
"we have not got a dataset for the dbsearch <BR>$db_obj->{'complex_search'}; ";
		$c->res->redirect( $c->uri_for("/error") );
		$c->detach();
	}

#Carp::confess( root::get_hashEntries_as_string ($oldDataset, 3, "we have a problem with the returned value for the search '$db_obj->{'complex_search'}'\n "));
#return 0 unless ( ref($db_obj) =~ m/\w/ );

	my ( @link_out, $form_hash, $selections, $temp, $list_vars );

	Carp::confess(
		ref($self)
		  . "::Add_add_form -> Sorry, but we did not get a usable object ($db_obj)"
	) unless ( $db_obj->isa('variable_table') );
	$self->formbuilder->method('post');
	foreach
	  my $variable_def ( @{ $db_obj->{'table_definition'}->{'variables'} } )
	{
		if ( defined $variable_def->{'data_handler'} ) {
			## we need to add a select box or something like that containing the possible entries
			## and all these datasets have to come first, as they might need a forking
			## to a Add_2_Dataset_form of the downstream table!
			if (
				ref(
					$db_obj->{'data_handler'}
					  ->{ $variable_def->{'data_handler'} }
				) eq "scientistTable"
			  )
			{
				## you must not select any scientist but yourselve unless you are a administrator
				$temp = $c->user();
				unless ( $c->model("ACL")->user_has_role( "$temp", 'admin' ) ) {
					$self->init_search_variables();
					$self->{'where_array'} =
					  [ [ "scientistTable.username", '=', 'my_value' ] ];
					$self->{'values_array'} = ["$temp"];
					$temp = $self->Add_select_form(
						$c,
						$variable_def->{'name'},
						$db_obj->{'data_handler'}
						  ->{ $variable_def->{'data_handler'} },
						$hash->{'come_from'} . ref($db_obj),
						$oldDataset->{ ref($db_obj)
							  . ".$variable_def->{'name'}" }
					);

					if ( ref( $temp->{'selected'} ) eq "ARRAY" ) {
						$selections->{ $variable_def->{'name'} } =
						  $temp->{'selected'};
					}
					push( @link_out, @{ $temp->{'links'} } );
					$self->init_search_variables();
					if ( defined $self->{'warn'} ) {
						$self->{'form_array'} = [];
						$c->stash->{'note'} =
						  "We did not find values in the table "
						  . $db_obj->{'data_handler'}
						  ->{ $variable_def->{'data_handler'} }->TableName()
						  . ".<BR>Therefore I sent you to the right table...";
						$self->Add_add_form(
							$c,
							{
								'redirect_on_success' =>
"/add_2_model/List_Table/$hash->{'come_from'}",
								'db_obj' => $db_obj->{'data_handler'}
								  ->{ $variable_def->{'data_handler'} },
								'come_from' =>
								  "/add_2_model/index/$hash->{'come_from'}"
							}
						);
						return;
					}
					next;
				}
			}    # <-- end if ( scientistTable )
			elsif (
				$db_obj->{'data_handler'}->{ $variable_def->{'data_handler'} }
				->isa('basic_list') )
			{
				## we absolutely need to take care to NOT use that id as an simple ID!!
				$list_vars->{ $variable_def->{'name'} } =
				  $db_obj->{'data_handler'}
				  ->{ $variable_def->{'data_handler'} };
			}
			$self->init_search_variables();

			$temp = $self->Add_select_form(
				$c,
				$variable_def->{'name'},
				$db_obj->{'data_handler'}->{ $variable_def->{'data_handler'} },
				$hash->{'come_from'} . ref($db_obj),
				$oldDataset->{ ref($db_obj) . ".$variable_def->{'name'}" }
			);
			if ( defined $self->{'warn'} ) {
				$self->{'form_array'} = [];
				$c->stash->{'note'} =
				  "We did not find values in the table "
				  . $db_obj->{'data_handler'}
				  ->{ $variable_def->{'data_handler'} }->TableName()
				  . ".<BR>Therefore I sent you to the right table...";
				$self->Add_add_form(
					$c,
					{
						'redirect_on_success' =>
						  "/add_2_model/index/$hash->{'come_from'}",
						'db_obj' => $db_obj->{'data_handler'}
						  ->{ $variable_def->{'data_handler'} },
						'come_from' => "/add_2_model/index/$hash->{'come_from'}"
					}
				);
				return;
			}

		  #			$c->stash->{"message"} .=
		  #			    "we added a search for for the user "
		  #			  . $c->user()
		  #			  . " using the db_search '"
		  #			  . $db_obj->{'data_handler'}->{ $variable_def->{'data_handler'} }
		  #			  ->{'complex_search'}
		  #			  . " on the db_class "
		  #			  . ref(
		  #				$db_obj->{'data_handler'}->{ $variable_def->{'data_handler'} } )
		  #			  . "\n";

			if ( ref( $temp->{'selected'} ) eq "ARRAY" ) {

#Carp::confess( "we have got a list for the var name $variable_def->{'name'}\n");
				$selections->{ $variable_def->{'name'} } = $temp->{'selected'};
			}
			push( @link_out, @{ $temp->{'links'} } );
		}    # <-- end if ( data_handler )
	}    # <-- end foreach
	$c->stash->{'LinkOut'} = [@link_out];

	foreach
	  my $variable_def ( @{ $db_obj->{'table_definition'}->{'variables'} } )
	{

		#		$c->stash->{'message'} .=
		#		  root::get_hashEntries_as_string( $variable_def, 3,
		#			"a variable def " );
		next if ( defined $variable_def->{'data_handler'} );
		next if ( $variable_def->{'hidden'} );
		next if ( $variable_def->{'name'} eq "id" );
		my $form_hash = {};
		$form_hash->{'comment'} = $variable_def->{'description'}
		  if ( $variable_def->{'description'} =~ m/\w/ );
		$form_hash->{'name'} = $variable_def->{'name'};
		if ( uc( $variable_def->{'type'} ) =~ m/INTEGER/ ) {
			$form_hash->{'validate'} = '/\d*/';
		}
		$form_hash->{'value'} =
		  $oldDataset->{ $db_obj->TableName() . ".$variable_def->{'name'}" };
		$form_hash->{'type'} = 'text';
		$form_hash->{'required'} = 1 if ( $variable_def->{'NULL'} == 0 );
		$form_hash->{'type'} = $variable_def->{'www_type'} if ( defined $variable_def->{'www_type'});
		push( @form_array, $form_hash );
	}
	push(
		@form_array,
		{
			'type'   => 'text',
			'name'   => 'id',
			'hidden' => 1,
			'value'  => $oldDataset->{ $db_obj->TableName() . ".id" }
		}
	);

	if ( $self->formbuilder->submitted && $self->formbuilder->validate ) {
		foreach $form_hash (@form_array) {
			$self->formbuilder->field(%$form_hash);
		}
		my @data;
		my $dataset = {};
		my $lists;
		foreach my $field ( $self->formbuilder->fields ) {
			@data = $self->formbuilder->field($field);
			$dataset->{$field} = $data[0];
		}
		foreach my $var ( keys %$selections ) {
			## Sumetimes, the resulting dataset could be a list!!
			if ( defined( $list_vars->{$var} ) ) {

				#Carp::confess ( "we have a list variable here: $var\n");
				##Oh fuck - we got a list!! That translates into the fact, that the values are 'others'->{id} values!!
				$lists->{$var}   = $selections->{$var};
				$dataset->{$var} = 0;
			}
			else {
				$dataset->{$var} = @{ $selections->{$var} }[0];
			}

		}
		my $id;
		foreach my $list_var_name ( keys %$lists ) {
			$dataset->{$list_var_name} =
			  $oldDataset->{ $db_obj->TableName() . ".$list_var_name" };
		}

#Carp::confess( root::get_hashEntries_as_string ($dataset, 3, "why do we delete the list ids with this dataset?"));
		if ( defined $dataset->{'pw'} && defined $dataset->{'username'}){
			my $temp =  $c->_hash_pw( $dataset->{'username'}, $dataset->{'pw'});
			#Carp::confess ( "I have a password that I want to hash: '$dataset->{'pw'}' -> '$temp' \n");
			$dataset->{'pw'} = $c->_hash_pw($dataset->{'username'}, $dataset->{'pw'});
		}
		$id = $db_obj->UpdateDataset($dataset);

		foreach my $list_var_name ( keys %$lists ) {
			next if ( $self->{'do_not_add_lists'} );

#next if ($list_vars->{$list_var_name} eq 'roles_list_id' && ! ( $c->model("ACL")->user_has_role( $c->user, 'admin' )));
			$list_vars->{$list_var_name}->UpdateList(
				{
					'list_id' =>
					  $oldDataset->{ $db_obj->TableName() . ".$list_var_name" },
					'other_ids' => $lists->{$list_var_name}
				}
			);
		}
		if ( $redirect_on_success =~ m/\w/ ) {
			$redirect_on_success =~ s/##ID##/$id/;
			foreach my $var_name ( keys %$dataset ) {
				if ( $redirect_on_success =~ s/##VAR_$var_name##/$dataset->{$var_name}/ && ! defined $dataset->{$var_name}){
					Carp::confess ( "You wanted to modify the ##VAR_$var_name##, but I do not have any info in my dataset!" );
				}
			}

   #Carp::confess( "Add_add_form - we should redirect to $redirect_on_success");
			$c->res->redirect( $c->uri_for($redirect_on_success) );
			$c->detach();
		}
		else {

#Carp::confess ( root::get_hashEntries_as_string ($dataset, 3, "we try to insert the new tyble entry using this hash: ") );
			$c->stash->{'message'} .=
			  "data stored - we got the id " . $db_obj->AddDataset($dataset);
		}
		$c->res->redirect('/');
		$c->detach();
	}
	else {
		push( @{ $self->{'form_array'} }, @form_array );
	}

	$c->stash->{'title'} = ref($db_obj);
	return $self;
}

sub DateTime {
	my ($date) = @_;
	my $date_format = DateTime::Format::Strptime->new(
		pattern   => '%F',                    # for YYYY-MM-DD american dates
		locale    => 'en_AU',
		time_zone => 'Australia/Melbourne',
		on_error  => sub { return 0 }
	);
	return $date_format->parse_datetime($date) if ( defined $date );
}

sub finalize {
	my ( $self, $c, $name ) = @_;
	if ( defined $name ) {
		$c->stash->{'sidebar'} =
		  $c->model('LinkList')->GetSidbar_4( $name, $c->user , $c );
	}
	else {
		$c->stash->{'sidebar'} =
		  $c->model('LinkList')->GetSidbar_4( ref($self), $c->user , $c );
	}
	return 1;
}

sub send_mail_to_admins : Local {
	my ( $self, $c, $betreff, $string ) = @_;
	unless ( $c->model("ACL")->user_has_role( $c->user, 'admin' ) ) {
		$c->res->redirect('/access_denied');
		$c->detach();
	}
	$self->__send_mail_to_admins( $c, $betreff, $string );
}

sub __send_mail_to_admins {
	my ( $self, $c, $betreff, $string ) = @_;
	return 0 unless ( defined $string );
	return 0 unless ( $string =~ m/\w/ );
	$betreff = "---" unless ( defined $betreff );
	my $admins = $c->model("ACL")->get_data_table_4_search(
		{
			'search_columns' => ['email'],
			'where'          => [ [ 'roles.name', '=', 'my_value' ] ],
		},
		'admin'
	)->get_column_entries('email');

#Carp::confess ( root::get_hashEntries_as_string ($admins, 3, "we got this data for the search '".$c->model("ACL")->{complex_search}."' "));
	if ( @$admins > 0 ) {
		my $ret;
		$ret = $c->model('SendMail')->MailMsg(
			'to'    => $admins,
			subject => $betreff,
			msg     => $string
		);
		Carp::confess(
			"I tried to send a mail to @$admins and got the return value $ret\n"
		) unless ( ref($ret) eq "HASH" );
	}
	return 1;
}

=head Add_add_form

This function is quite complex and does not do an extra user check! Probably that is an error and should be corrected...

Variables: the catalyst stash and another hash containing all the additional configuratiohn values:

=over

=item 'db_obj'
The name of the database object you want to add to

=item 'downstream_table'
The name of the downstream table object, iof you do want to link directly to the downstream table. 
Keep in mind, that you can not add to a list table!

=item 'redirect_on_success'
A link we should follow upon sucess. This data might contain a '##ID##' tag, 
that is automatically changed to the ID that of the new dataset.

=item 'predefined_values'
If you want to add some constants, that can not be changed using the web friontend, 
but that are necessary to create the table entry, you should add the values as 'predefined_values' => { <value_name> => <your choosen value> }.
The data will be added as hidden filed to the form.

=item 'mail_to_admin'
A binary value if we should mail the values, that we just inserted into the table to the admins.

=back

=cut

=head2 __do_after_Add_Datset

Use this function to create a Controller specififc function executaed right after a new dataset entry has been created.
This function has some atvantages over the variable_table::post_INSERT_INTO_DOWNSTREAM_TABLES(), because here we have a full access to all the 
Genexpress_catalist variables - especially the cookie!

A disatvantage might be the, that this function does not know which things have been added, but that might be a little useless,
as the ID should anable each function to gather the neccessary information form the database.
=cut

sub __do_after_Add_Datset {
	## create the link between experiment and the LabBook section
	my ( $self, $c, $id ) = @_;
	return 1;
}

=header2 Add_add_form ( {
	'db_obj',
	'downstream_table',
	'redirect_on_success',
	'predefined_values'
});

This function will create the form to add to the database table given as 'db_obj'.
Fire and forget!

redirect will be used like $c->uri_for($redirect_on_success)

=cut

sub Add_add_form {

#Carp::confess( "Add_add_form - we got the variables ". root::print_hashEntries( [@_], 3," "));
	my ( $self, $c, $hash ) = @_;
	my ( $db_obj, $downstream_table, $redirect_on_success );
	$db_obj              = $hash->{'db_obj'};
	$downstream_table    = $hash->{'downstream_table'};
	$redirect_on_success = $hash->{'redirect_on_success'};
	my $predefined = $hash->{'predefined_values'};
	$predefined = {} unless ( ref($predefined) eq "HASH" );
	my @form_array;
	Carp::confess(
		ref($self) . "::Add_add_form -> we do not have a \$c variable ($c)\n" )
	  unless ( ref($c) =~ m/\w/ );

	#return 0 unless ( ref($db_obj) =~ m/\w/ );

	my ( @link_out, $form_hash, $selections, $temp, $list_vars );

	Carp::confess(
		ref($self)
		  . "::Add_add_form -> Sorry, but we did not get a usable object ($db_obj)"
	) unless ( $db_obj->isa('variable_table') );
	$self->formbuilder->method('post');

	foreach
	  my $variable_def ( @{ $db_obj->{'table_definition'}->{'variables'} } )
	{
		next if ( defined $predefined->{ $variable_def->{'name'} } );

		if ( defined $variable_def->{'data_handler'} ) {

			## we need to add a select box or something like that containing the possible entries
			## and all these datasets have to come first, as they might need a forking
			## to a Add_2_Dataset_form of the downstream table!
			if (
				ref(
					$db_obj->{'data_handler'}
					  ->{ $variable_def->{'data_handler'} }
				) eq "scientistTable"
			  )
			{
				## you must not select any scientist but yourselve unless you are a administrator
				$temp = $c->user();
				unless ( $c->model("ACL")->user_has_role( "$temp", 'admin' ) ) {
					$self->init_search_variables();
					$self->{'where_array'} =
					  [ [ "scientistTable.username", '=', 'my_value' ] ];
					$self->{'values_array'} = ["$temp"];
					$temp = $self->Add_select_form(
						$c,
						$variable_def->{'name'},
						$db_obj->{'data_handler'}
						  ->{ $variable_def->{'data_handler'} },
						$hash->{'come_from'} . ref($db_obj),
						$variable_def->{'link_to'}
					);

					if ( ref( $temp->{'selected'} ) eq "ARRAY" ) {
						$selections->{ $variable_def->{'name'} } =
						  $temp->{'selected'};
					}
					push( @link_out, @{ $temp->{'links'} } );
					$self->init_search_variables();
					if ( defined $self->{'warn'} ) {
						$self->{'form_array'} = [];
						$c->stash->{'note'} =
						  "We did not find values in the table "
						  . $db_obj->{'data_handler'}
						  ->{ $variable_def->{'data_handler'} }->TableName()
						  . ".<BR>Therefore I sent you to the right table...";
						$self->Add_add_form(
							$c,
							{
								'redirect_on_success' =>
"/add_2_model/List_Table/$hash->{'come_from'}",
								'db_obj' => $db_obj->{'data_handler'}
								  ->{ $variable_def->{'data_handler'} },
								'come_from' =>
								  "/add_2_model/index/$hash->{'come_from'}"
							}
						);
						return;
					}
					next;
				}
			}    # <-- end if ( scientistTable )
			elsif (
				$db_obj->{'data_handler'}->{ $variable_def->{'data_handler'} }
				->isa('basic_list') )
			{
				if ( defined $predefined->{ $variable_def->{'name'} } ) {
					## OK I do not want to select ANYTHING from that!
				}
				else {
					## we absolutely need to take care to NOT use that id as an simple ID!!
					$list_vars->{ $variable_def->{'name'} } = 1;
				}

			}
			$self->init_search_variables();

			if ( defined $predefined->{ $variable_def->{'name'} } ) {
				## we do not need to add the select form, instead I want to have a hidden field!
				push(
					@{ $self->{'form_array'} },
					{
						'name'  => $variable_def->{'name'},
						'value' => $predefined->{ $variable_def->{'name'} },
						'type'  => 'hidden'
					}
				);
			}
			else {
				$temp = $self->Add_select_form(
					$c,
					$variable_def->{'name'},
					$db_obj->{'data_handler'}
					  ->{ $variable_def->{'data_handler'} },
					$hash->{'come_from'} . ref($db_obj)
				);
			}
			if ( defined $self->{'warn'} ) {
				$self->{'form_array'} = [];
				$c->stash->{'note'} =
				  "We did not find values in the table "
				  . $db_obj->{'data_handler'}
				  ->{ $variable_def->{'data_handler'} }->TableName()
				  . ".<BR>Therefore I sent you to the right table...";
				$self->Add_add_form(
					$c,
					{
						'redirect_on_success' =>
						  "/add_2_model/index/$hash->{'come_from'}",
						'db_obj' => $db_obj->{'data_handler'}
						  ->{ $variable_def->{'data_handler'} },
						'come_from' =>
						  "/add_2_model/index/$hash->{'come_from'}",
						'predefined_values' => $predefined
					}
				);
				return;
			}

			if ( ref( $temp->{'selected'} ) eq "ARRAY" ) {
				$selections->{ $variable_def->{'name'} } = $temp->{'selected'};
			}
			push( @link_out, @{ $temp->{'links'} } );
		}    # <-- end if ( data_handler )
	}    # <-- end foreach
	$c->stash->{'LinkOut'} = [@link_out];

	foreach
	  my $variable_def ( @{ $db_obj->{'table_definition'}->{'variables'} } )
	{
		if ( $predefined->{ $variable_def->{'name'} } ) {
			push(
				@form_array,
				{
					'name'  => $variable_def->{'name'},
					'label' => $variable_def->{'name'},
					'type'  => 'hidden',
					'value' => $predefined->{ $variable_def->{'name'} }
				}
			);
			next;
		}
		next if ( defined $variable_def->{'data_handler'} );
		next if ( $variable_def->{'hidden'} );
		next if ( $variable_def->{'name'} eq "md5_sum" );
		my $form_hash = {};
		$form_hash->{'comment'} = $variable_def->{'description'}
		  if ( $variable_def->{'description'} =~ m/\w/ );
		$form_hash->{'name'} = $variable_def->{'name'};
		if ( uc( $variable_def->{'type'} ) =~ m/INTEGER/ ) {
			$form_hash->{'validate'} = '/\d*/';
		}
		$form_hash->{'type'} = 'text';
		if ( uc( $variable_def->{'type'} ) eq "TEXT" ) {
			$form_hash->{'type'} = 'textarea';
			$form_hash->{'cols'} = 80;
			$form_hash->{'rows'} = 20;
		}
		$form_hash->{'required'} = 1 if ( $variable_def->{'NULL'} == 0 );
		if ( defined $predefined->{ $variable_def->{'name'} } ) {
			$form_hash->{'value'} = $predefined->{ $variable_def->{'name'} };
			$form_hash->{'type'}  = 'hidden';
		}
		$form_hash->{'type'} = $variable_def->{'www_type'} if ( defined $variable_def->{'www_type'});
		push( @form_array, $form_hash );
		if ( uc( $variable_def->{'type'} ) eq "DATE" ) {
			##FUCK - there is no formbuilder data field!!!
			$form_hash->{'comment'} =
			  "format:YYYY-MM-DD - $form_hash->{'comment'}";
			$form_hash->{inflate} = \&DateTime;
		}
		if ( $variable_def->{'file_upload'} ) {
			$form_hash->{type} = 'file';
		}

	}

	if ( $self->formbuilder->submitted && $self->formbuilder->validate ) {
		## In case we have a User Table Add-Form we will not do anything here!
		if ( ref($db_obj) eq "scientistTable" ){
			push( @{ $self->{'form_array'} }, @form_array );
			next;
		}
		foreach $form_hash (@form_array) {
			$self->formbuilder->field(%$form_hash);
		}
		my @data;
		my $dataset = $self->__process_returned_form($c);
		my $lists;

		foreach my $var ( keys %$selections ) {
			## Sometimes, the resulting dataset could be a list!!
			if ( $list_vars->{$var} ) {

				#Carp::confess ( "we have a list variable here: $var\n");
				##Oh fuck - we got a list!! That translates into the fact, that the values are 'others'->{id} values!!
				$lists->{$var}   = $selections->{$var};
				$dataset->{$var} = 0;
			}
			else {
				$dataset->{$var} = @{ $selections->{$var} }[0];
			}
			$dataset->{$var} = $predefined->{$var} if ( defined $predefined->{$var});

		}
		foreach ( keys %$predefined){
			$dataset->{$_} = $predefined->{$_};
		}
		$dataset->{'LabBook_id'} = $c->session->{'LabBook_id'} if ( defined $db_obj->datanames()->{'LabBook_id'} );
		my $id;
		$id = $db_obj->AddDataset($dataset);
		foreach my $list_var_name ( keys %$lists ) {
			## shit - if a dataset handles more than one List - what should I do???
			$db_obj->Add_2_list(
				{
					'my_id'     => $id,
					'var_name'  => $list_var_name,
					'other_ids' => $lists->{$list_var_name}
				}
			);
		}
		unless ( defined $id ) {
			$c->stash->{'error'} = root::get_hashEntries_as_string( $dataset, 3,
"We did not get a result while adding this dataset to the db_object $db_obj:"
			  )
			  . "\nInstead we got this error:\n"
			  . $db_obj->{error};
			$c->stash->{'template'} = "error.tt2";
			return;
		}
		##OK we have added the ID to the databse - perhaps there are some Controller specific things to do?
		$self->__do_after_Add_Datset( $c, $id, $db_obj );
		if ( $hash->{'mail_to_admin'} ) {
			my $string = '';
			while ( my ( $var_name, $var_data ) = each %$dataset ) {
				$string .= "$var_name='$var_data'\n";
			}
			my $user = $c->user();
			$self->__send_mail_to_admins( $c,
				"user $user added to table " . $db_obj->TableName(), $string );
		}
		
		if ( $redirect_on_success =~ m/\w/ ) {
			$redirect_on_success =~ s/##ID##/$id/;
			foreach my $var_name ( keys %$dataset ) {
				if ( $redirect_on_success =~ s/##VAR_$var_name##/$dataset->{$var_name}/ && ! defined $dataset->{$var_name}){
					Carp::confess ( "You wanted to modify the ##VAR_$var_name##, but I do not have any info in my dataset!" );
				}
			}
   #Carp::confess( "Add_add_form - we should redirect to $redirect_on_success");
			$c->res->redirect( $c->uri_for($redirect_on_success) );
			$c->detach();
		}
		else {

#Carp::confess ( root::get_hashEntries_as_string ($dataset, 3, "we try to insert the new tyble entry using this hash: ") );
#$c->stash->{'message'} .=
# "data stored - we got the id " . ;
			$db_obj->AddDataset($dataset);
		}
		$c->res->redirect('/');
		$c->detach();
	}
	else {
		push( @{ $self->{'form_array'} }, @form_array );
	}

	#$c->stash->{'FormBuilder'} = $self->formbuilder();
	#$c->stash->{'message'} .= "Do you see anything??";
	$self->finalize($c);
	$c->stash->{'title'} = ref($db_obj);
	return $self;
}

sub __process_returned_form {
	my ( $self, $c ) = @_;
	my ( $dataset, @data, $str );
	foreach my $field ( $self->formbuilder->fields ) {
		$str .= "$field; ";
		if ( $field->{'type'} eq "file" ) {
			## OK - upload the file and give the script the linked position...
			my $upload   = $c->req->upload($field);
			Carp::confess ( "I tried to upload the field of name $field->{'name'} "."which should be a file, but I got no file object but (".$upload.")!\n".
			"A frequent error is to not use the 'post' methood for the page (missing the line '$self->formbuilder->method('post');')\n") unless ( ref($upload) =~m/\w/ );
			my $filename = $upload->filename;
			my $target =
			  $c->model('configuration')
			  ->GetConfigurationValue_for_tag('web_temp_path') . "/$filename";
			$target =~ s/\s/_/g;
			$target =~ s/[\)\(\:]/_/g;
			unless (  $upload->link_to($target)
				|| $upload->copy_to($target) )
			{
				if ( $! =~m/Die Datei existiert bereits/  ){
					$dataset->{$field} = $target;
				}
				elsif ( $! =~m/File exists/){
					$dataset->{$field} = $target;
				}
				else {
					Carp::confess("Failed to copy '$filename' to '$target': $!");
				}
				
			}
			else {
				$dataset->{$field} = $target;
			}
		}
		elsif ( $field->{'multiple'} ) {
			@data = $self->formbuilder->field($field);
			$dataset->{$field} = [@data];

#Carp::confess ( "Wow - why does that not work?? $field => ".join(", ",@{$dataset->{$field}})."\n");
		}
		else {
			@data = $self->formbuilder->field($field);
			$dataset->{$field} = $data[0];
		}
	}
	return $dataset;
}

=head2 Add_select_form

This function uses a variable_table instance to create forms,
where the user can either select database entries based on thir unique key, 
or you can modify the search, the module performes by setting some variables,
that will be directly fead to variable_table->getArray_of_Array_for_search({},@_).
Therefore you can get a more detailed descriptions of the variables from variable_table::getArray_of_Array_for_search
documentaion.
The variables are:
1. $self->{'where_array'}
2. $self->{'values_array'} (the @ in getArray_of_Array_for_search)
3. $self->{'order_by'}

=cut

sub init_search_variables {
	my ($self) = @_;
	$self->{'where_array'}         = [];
	$self->{'values_array'}        = [];
	$self->{'order_by'}            = undef;
	$self->{'select_column_names'} = undef;
	return 1;
}

=head3 Add_select_form

This is a very central function, as it creates lelect formentries from variable_table databse objects.

In order to work properly, this function needs a $c variable, a name of the column, the db object 
and an optional string of higher order databse objects and an optional column name, 
if you do not want to select the id from the tables.

You can access the selected values from the 'selected' key of the returned hash.
=cut

sub Add_select_form {
	my ( $self, $c, $variable_name, $db_obj, $come_from, $select_from_table ) =
	  @_;
	my @come_from;
	@come_from = ($come_from) if ( defined $come_from );
	my $return = {};
	$come_from = join( "/", @come_from );
	$come_from =~ s!//!/!g;
	$self->{'warn'} = undef;
	my $basic_list = 0;
	my @form_array;
	$select_from_table ||= "id";

#$c->stash->{'message'} .= ref($self)."::Add_select_form - we live (0, $c)!!!\n";
	Carp::confess(
		ref($self)
		  . "::Add_select_form -> we do not have a \$c variable ($c)\n" )
	  unless ( ref($c) =~ m/\w/ );

#$c->stash->{'message'} .=  ref($self)."::Add_select_form - we live (1, $self, $self)!!!\n";
	Carp::confess(
		ref($self)
		  . "::Add_select_form -> we do not have a \$db_obj variable ($db_obj)\n"
	) unless ( ref($db_obj) =~ m/\w/ );

  #$c->stash->{'message'} .=  ref($self)."::Add_select_form - we live (2)!!!\n";
	$self->{'where_array'}  = [] unless ( defined $self->{'where_array'} );
	$self->{'values_array'} = [] unless ( $self->{'values_array'} );

	my @columnNames;

	if ( defined $db_obj->{'data_handler'}->{'otherTable'}
		&& $come_from =~ m/\w/ )
	{
		$come_from .= "/" . ref($db_obj);
		$db_obj = $db_obj->{'data_handler'}->{'otherTable'};

#Carp::confess( ref($self). "::Add_select_form - we stumbled accross a basic_list! \$come_from = $come_from\n");
		$basic_list = 1;
	}
	if ( ref( $self->{'select_column_names'} ) eq "ARRAY" ) {
		@columnNames = @{ $self->{'select_column_names'} };
	}
	elsif ( defined $db_obj->{'data_handler'}->{'otherTable'} ) {
		## oops - we got a sample list as first entry!
		@columnNames =
		  @{ $db_obj->{'data_handler'}->{'otherTable'}->{'UNIQUE_KEY'} };
	}
	else {
		unless ( defined $db_obj->{'UNIQUE_KEY'} ) {
			foreach my $variable_def (
				@{ $db_obj->{'table_definition'}->{'variables'} } )
			{
				push( @columnNames,
					ref($db_obj) . "." . $variable_def->{'name'} );
			}
		}
		else {
			foreach my $variable_name ( @{ $db_obj->{'UNIQUE_KEY'} } ) {
				push( @columnNames, ref($db_obj) . "." . $variable_name );
			}
		}
	}
	my $data;
	if ( ref( $self->{'order_by'} ) eq "ARRAY" ) {
		$data = $db_obj->getArray_of_Array_for_search(
			{
				'search_columns' =>
				  [ ref($db_obj) . ".$select_from_table", @columnNames ],
				'where'    => $self->{'where_array'},
				'order_by' => $self->{'order_by'},
			},
			@{ $self->{'values_array'} }
		);
	}
	else {
		$data = $db_obj->getArray_of_Array_for_search(
			{
				'search_columns' =>
				  [ ref($db_obj) . ".$select_from_table", @columnNames ],
				'where'    => $self->{'where_array'},
				'order_by' => [ ref($db_obj) . ".$select_from_table" ]
			},
			@{ $self->{'values_array'} }
		);
	}

	#$c->stash->{'message'} .= $db_obj->{'complex_search'};
	my ( @options, $id, $i );
	$i = 0;
	foreach my $line (@$data) {
		$id = shift(@$line);
		$options[$i] = { $id => join( "; ", @$line ) };
		$i++;
	}

	#$self->{'warn'} = join( "/", @come_from, ref($db_obj) ) if ( $i == 0 );
	if ($basic_list) {
		$self->{'warn'} = undef;
		push(
			@form_array,
			{
				'name'     => $variable_name,
				'required' => 1,
				'options'  => \@options,
				'multiple' => 1
			}
		);
	}
	elsif ( $self->{'select_multiple'} ) {
		push(
			@form_array,
			{
				'name'     => $variable_name,
				'required' => 1,
				'multiple' => 1,
				'options'  => \@options
			}
		);
	}
	else {
		push(
			@form_array,
			{
				'name'     => $variable_name,
				'required' => 1,
				'options'  => \@options
			}
		);
	}
	unless ( scalar(@options) >= 1 ) {
		## This will lead to the re-linking process, that destroies the usabillity of the whole database!
		## $self->{'warn'} .=
		## "Sorry, but we have no columns for the search $db_obj->{'complex_search'}";

		push(
			@form_array,
			{
				'name'     => $variable_name,
				'type'     => 'textarea',
				'cols'     => 30,
				'rows'     => 2,
				'required' => 1,
				'value'    => '!!ERROR!! please add to the '
				  . ref($db_obj)
				  . ' and reload that form',
				'validate' => { state => /^\d+$/ }
			}
		);
	}

	if ( $self->formbuilder->submitted && $self->formbuilder->validate ) {
		$return->{'button'} = $self->formbuilder->submitted;
		foreach my $form_hash (@form_array) {
			$self->formbuilder->field(%$form_hash);
		}
		my @data;
		foreach my $field ( $self->formbuilder->fields ) {
			@data = $self->formbuilder->field($field);
			$return->{'selected'} = \@data;
		}

	}
	else {
		push( @{ $self->{'form_array'} }, @form_array );
	}
	$return->{'links'} = [];
	if ( ref( $db_obj->{'data_handler'} ) eq "ARRAY" ) {
		foreach ( @{ $db_obj->{'data_handler'} } ) {
			if ( ref( $c->model($_) ) =~ m/\w/ ) {
				push(
					@{ $return->{'links'} },
					{
						'href' => "/"
						  . lc( ref( $c->model($_) ) )
						  . "/AddDataset",
						'tag' => "Add to " . ref( $c->model($_) )
					}
				);
			}
			else {
				push(
					@{ $return->{'links'} },
					{
						'href' => "/add_2_model/index/" . $come_from . "/$_",
						'tag'  => "Add to " . $_
					}
				);
			}

		}
	}

	if ( ref( $c->model( ref($db_obj) ) ) =~ m/\w/ ) {
		push(
			@{ $return->{'links'} },
			{
				'href' => "/add_2_model/index/" .  ref($db_obj) . "/",
				'tag'  => "Add to " . ref($db_obj)
			}
		);
	}
	else {
		push(
			@{ $return->{'links'} },
			{
				'href' => "/add_2_model/index/$come_from/" . ref($db_obj),
				'tag'  => "Add to " . ref($db_obj)
			}
		);
	}
	$self->finalize($c);
	$c->stash->{'title'} = ref($db_obj);
	return $return;
}

=head1 NAME

Genexpress_catalist::Controller::base_db_controler - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

=head1 AUTHOR

Stefan Lang

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
