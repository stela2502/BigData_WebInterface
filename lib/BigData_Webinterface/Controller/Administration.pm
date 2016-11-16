package BigData_Webinterface::Controller::Administration;

use strict;
use warnings;
use BigData_Webinterface::base_db_controler;
use base 'BigData_Webinterface::base_db_controler';

=head1 NAME

Genexpress_catalist::Controller::Administration - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Local {
	my ( $self, $c, @args ) = @_;
	$self->__check_user( $c, 'admin' );

	$c->stash->{'html'}     = 'Administration Interface';
	$c->stash->{'template'} = 'Administration.tt2';

#Carp::confess( "we tried to get the right sidebar using (".ref($self).", ".$c->user." )!\n");
	$self->finalize($c);
}

sub execute_script : Local {
	my ( $self, $c, $script_name ) = @_;
	$self->__check_user( $c, 'admin' );

	#unless ( $c->model("ACL")->user_has_role( $c->user, 'admin' ) ) {
	#	$c->res->redirect( $c->uri_for('/access_denied') );
	#	$c->detach();
	#}
	## we need to set the LabBook ID - a special Administration log LabBook!
	## first we need to get the administration LogBook

	my $script_id = $c->model('Executables')->get_Executable_id($script_name);

	my $LabBook_instance =
	  $c->model('LabBook')->Get_Admin_LogBook( $c->user() );
	my $hash = $LabBook_instance->get_data_table_4_search(
		{
			'search_columns' => [ 'LabBook_instance.id', 'text' ],
			'where'          => [
				[ 'header1',       '=', 'my_value' ],
				[ 'header2',       '=', 'my_value' ],
				[ 'header3',       '=', 'my_value' ],
				[ 'creation_date', '=', 'ma_value' ]
			]
		},
		'automatic logs',
		$script_name,
		' ',
		root::Today()
	)->get_line_asHash(0);
	if ( ref($hash) eq "HASH" ) {
		$c->session->{'Entry_id'} = $LabBook_instance->AddDataset(
			{
				'header1' => 'automatic logs',
				'header2' => $script_name,
				'header3' => ' ',
				'text'    => $hash->{'text'} . "\n" . '('
				  . DateTime::Format::MySQL->format_datetime(
					DateTime->now()->set_time_zone('Europe/Berlin')
				  )
				  . '): you were relinked to '
				  . $c->uri_for("/executables/Execute/$script_id")
			}
		);
	}
	else {
		$c->session->{'Entry_id'} = $LabBook_instance->AddDataset(
			{
				'header1' => 'automatic logs',
				'header2' => $script_name,
				'header3' => ' ',
				'text'    => '('
				  . DateTime::Format::MySQL->format_datetime(
					DateTime->now()->set_time_zone('Europe/Berlin')
				  )
				  . '): you were relinked to '
				  . $c->uri_for("/executables/Execute/$script_id")
			}
		);
	}
	$c->{session}->{'LabBook_id'} = $LabBook_instance->{'LabBook_id'};
	$c->res->redirect( $c->uri_for("/executables/Execute/$script_id") );
	$c->detach();
}

sub Mail_2_all_users : Local : Form {
	my ( $self, $c, @args ) = @_;
	$self->__check_user( $c, 'admin' );

	#unless ( $c->model("ACL")->user_has_role( $c->user, 'admin' ) ) {
	#	$c->res->redirect( $c->uri_for('/access_denied') );
	#	$c->detach();
	#}
	$c->stash->{'sidebar'} =
	  $c->model('LinkList')->GetSidbar_4( ref($self), $c->user, $c );
	my $form_hash;
	$form_hash->{'type'}  = 'text';
	$form_hash->{'name'}  = 'Subject';
	$form_hash->{'label'} = 'Subject';
	$self->formbuilder->field(%$form_hash);
	$form_hash->{'type'}  = 'textarea';
	$form_hash->{'cols'}  = 80;
	$form_hash->{'rows'}  = 20;
	$form_hash->{'name'}  = 'email_text';
	$form_hash->{'label'} = 'email_text';
	$self->formbuilder->field(%$form_hash);

	if ( $self->formbuilder->submitted ) {
		my $dataset = $self->__process_returned_form($c);
		if ( $dataset->{'email_text'} =~ m/\w/ ) {
			my $hash =
			  $c->model('ACL')
			  ->get_data_table_4_search( { 'search_columns' => ['email'] } );
			if ( defined $hash ) {
				my $mails = $hash->get_column_entries('email');
				my $ret   = $c->model('SendMail')->MailMsg(
					{
						'to'      => shift @$mails,
						'cc'      => join( ", ", @$mails ),
						'subject' => $dataset->{'Subject'},
						'msg'     => $dataset->{'email_text'}
					}
				);
				$c->stash->{'message'} =
				    'Your mail was sent to the mail users:'
				  . join( ",", @$mails )
				  . "\n$ret\n";
				$c->stash->{'template'} = 'message.tt2';
				return 1;
			}
			else {
				$c->stash->{'error'} =
				  'Sorry - but we do not know where to sent the mails to.';
				$c->stash->{'message'} =
				    "the search '"
				  . $c->model('ACL')->{'complex_search'}
				  . "; has not returned anything!";
				$c->stash->{'template'} = "error.tt2";
				return 1;
			}
		}
	}
	$c->stash->{'template'}    = 'Form.tt2';
	$c->stash->{'title'}       = "Send a mail to all users";
	$c->stash->{'description'} = "Guess how :-)";
}

sub Admin_User_Interface : Local {
	my ( $self, $c, @args ) = @_;
	$self->__check_user( $c, 'admin' );

#	$c->stash->{'sidebar'} =
#	  $c->model('LinkList')->GetSidbar_4( ref($self), $c->user, $c );
	my $data_table      = $c->model("ACL")->Get_As_User_Table();
	my $username_column = $data_table->Header_Position('usernamr');
	for ( my $i = 0 ; $i < @{ $data_table->{'data'} } ; $i++ ) {
		@{ @{ $data_table->{'data'} }[$i] }[$username_column] =
		    '<a href="/administration/ModifyUser/'
		  . @{ @{ $data_table->{'data'} }[$i] }[$username_column] . '">'
		  . @{ @{ $data_table->{'data'} }[$i] }[$username_column] . '</a>';
	}
	$c->stash->{'LinkOut'} = [
		{ 'href' => "/administration/AddUser", 'tag' => 'Add a new user' },
		{
			'href' => "/add_2_model/index/Roles",
			'tag'  => 'Add a new role'
		},
		{
			'href' => "/add_2_model/index/Action_Groups",
			'tag'  => 'Add a new Action group'
		}
	];
	$c->stash->{'title'}    = "Select the scientist you want to modify";
	$c->stash->{'text'}     = $data_table->GetAsHTML();
	$c->stash->{'template'} = 'LabBook.tt2';
}

sub ModifyUser : Local : Form {
	my ( $self, $c, @args ) = @_;

	$self->__check_user($c);

	my $username = $c->user;
	my $admin    = 0;
	if ( $c->model("ACL")->user_has_role( $c->user, 'admin' ) ) {
		$username = $args[0] if ( defined $args[0] );
		$self->{'do_not_add_lists'} = 0;
		$admin = 1;
	}
	else {
		$self->{'do_not_add_lists'} = 1;
	}
	my $model =
	  $c->model("ACL")
	  ->get_as_object( $c->model("ACL")->Get_id_for_name($username) );
	$self->{'form_array'} = [ $model->get_formdef_array() ];
	
	unless ($admin) {
		foreach ( @{ $self->{'form_array'} } ) {
			if ( $_->{'name'} eq "action_gr_id" ) {
				$_->{'type'} = 'hidden';
			}
			elsif ( $_->{'name'} eq "roles_list_id" ) {
				$_->{'type'} = 'hidden';
			}
		}
	}
	foreach my $hash ( @{ $self->{'form_array'} } ) {
		$self->formbuilder->field(%$hash);
	}
	push(
		@{ $c->stash->{'LinkOut'} },
		{
			'href' => "/administration/Set_Start_Page/" . $username,
			'tag'  => 'Define your start page'
		}
	);
	if ( $self->formbuilder->submitted() ) {
		my $dataset = $self->__process_returned_form($c);
		## I need to somehow handle the passwords!!
		$dataset->{'pw'} = undef #$c->_hash_pw( $dataset->{'username'}, $dataset->{'pw'} )
		  unless ( $dataset->{'pw'} eq $model->{'pw'} );
		$model->process_my_values($dataset);
		$c->res->redirect(
			$c->uri_for('/administration/Admin_User_Interface/') );
		$c->detach();
	}
	$c->stash->{'title'} = "Update a Scientist dataset";
	$c->stash->{'text'}  =
	  "You can update the information on scientists here <BR>\n";

	$c->stash->{'template'} = 'LabBook.tt2';
}



sub Registration : Local : Form {
	my ( $self, $c, $security_tocken ) = @_;
	$c->stash->{'function'} = 'Register new user';
	$c->stash->{'template'} = 'Registration.tt2';
#	$c->stash->{'sidebar'}  =
#	  $c->model('LinkList')->GetSidbar_4( 'root', '', $c );
	if ( defined $security_tocken ) {
		my $temp =
		  stefans_libs::database::scienstTable::temporary_banned->new(
			$c->model('ACL') );
		my $data_table = $temp->get_data_table_4_search(
			{
				'search_columns' => [ ref($temp) . ".*" ],
				'where'          => [ [ 'md5_sum', '=', 'my_value' ] ],
			},
			$security_tocken
		);

#Carp::confess ( print root::get_hashEntries_as_string (  $data_table->get_line_asHash(0) , 3 , "where is the id?" ));
		$temp->UpdateDataset(
			{
				'id'     => $data_table->get_line_asHash(0)->{"temp_banned.id"},
				'active' => 'N'
			}
		);
		$c->res->redirect("/login/");
		$c->detach();
	}
	my $model = $c->model("ACL")->get_as_object();
	$self->{'form_array'} = [ $model->get_formdef_array() ];

	foreach ( @{ $self->{'form_array'} } ) {
		if ( $_->{'name'} eq "action_gr_id" ) {
			$_->{'type'} = 'hidden';
		}
		elsif ( $_->{'name'} eq "roles_list_id" ) {
			$_->{'type'} = 'hidden';
		}
	}

	foreach my $hash ( @{ $self->{'form_array'} } ) {
		$self->formbuilder->field(%$hash);
	}
	if ( $self->formbuilder->submitted() ) {
		my $dataset = $self->__process_returned_form($c);
		## I need to somehow handle the passwords!!
		my ( $pw, $nix, $salt ) = $c->_hash_pw($dataset->{'username'}, $dataset->{'pw'} )
		  unless ( $dataset->{'pw'} eq $model->{'pw'} );
		$dataset->{'pw'} = $pw;
		$dataset->{'salt'} = $salt;

		$dataset->{'action_gr_id'} = [
			$c->model('ACL')->{'data_handler'}->{'action_group_list'}
			  ->{'data_handler'}->{'otherTable'}->AddDataset(
				{
					'name'        => 'new user',
					'description' =>
'These users have registered themselves using the web frontend.'
				}
			  )
		];
		$dataset->{'roles_list_id'} =
		  [ $c->model('ACL')->{'data_handler'}->{'role_list'}->{'data_handler'}
			  ->{'otherTable'}->AddDataset( { 'name' => 'user' } ) ];

   #Carp::confess ( "\$exp = " . root->print_perl_var_def( $dataset ) . ";\n" );
		$model->process_my_values($dataset);
		my $temp =
		  stefans_libs::database::scienstTable::temporary_banned->new(
			$c->model('ACL') );
		my $dataset_new = {
			'scientist_id' => $model->{'database_id'},
			'cause'        =>
			  'Anonymous user is allowed to add a user over the internet.',
			'active' => 'Y'
		};
		$temp->AddDataset($dataset_new);
		$security_tocken = $dataset_new->{'md5_sum'};
		my $ret = $c->model('SendMail')->MailFile(
			{
				'to'    => $model->{'email'},
				subject => 'Please activate your account',
				msg     => "Hi "
				  . $model->{'name'}
				  . "!\nYou have registered for a account at the open ELN hosted on "
				  . $c->uri_for('/') . ".\n"
				  . "To finish your registration process please follow this link: "
				  . $c->uri_for("/administration/Registration/$security_tocken")
				  . " \n"
				  . "just for your information I have attached the pdflatex log file to this mail.\n"
			}
		);
		$c->res->redirect( $c->uri_for('/access_denied/')
			  . $c->uri_for("/administration/Registration/$security_tocken") );
		$c->detach();
	}
	$c->stash->{'title'} = "Update a Scientist dataset";
	$c->stash->{'text'}  =
	  "You can update the information on scientists here <BR>\n";

}

=head2 automatic_set_start_page

This Web Page is a automatic landing page for the 'Make this page my start page' button.
It does the required thing and reports that it has done it.
Nothing else.

=cut

sub automatic_set_start_page : Local  {
	my ( $self, $c, $username, @page ) = @_;
	if ( $c->user() eq $username ) {
		$self->__check_user($c);
	}
	else {
		$self->__check_user( $c, 'admin' );
	}
	my $not_necessary = pop ( @page );
	unless ( "$not_necessary" eq 'jemplate' ) {
		push( @page, $not_necessary );
		$not_necessary = '';
	}
	#Carp::confess ( "The page information: '".join("', '",@page)."'");
	my $user_id = $c->model('ACL')->Get_id_for_name($username);
	my $hash    = $c->model('Start_Page')->get_data_table_4_search(
		{
			'search_columns' => [ ref( $c->model('Start_Page') ) . '.*' ],
			'where'          => [ [ 'username', '=', 'my_value' ] ]
		},
		$username
	)->get_line_asHash(0);
	if ( defined $hash ) {
		foreach ( keys %$hash ) {
			if ( $_ =~ m/page$/ ) {
				if ( $hash->{$_} eq join( "/", @page ) ) {
					#Carp::confess ( "The page information is already: '".join("', '",@page)."'");
				}
				elsif ( @page == 0 ) {
					$c->model('Start_Page')->delete_entry(
						{
							'user_id' => $user_id,
							'id'      => $hash->{'start_page.id'}
						}
					);
				}
				else {
					
					$c->model('Start_Page')->UpdateDataset(
						{
							'page'    => "/".join( "/", @page ),
							'id'      => $hash->{'start_page.id'}
						}
					);
					#Carp::confess ( "The page information is changed to: '".join("', '",@page)."' and will be updated using the id '$hash->{'start_page.id'}'");
				}
			}
		}
	}
	else {
		$c->model('Start_Page')->AddDataset(
			{
				'page'    => "/".join( "/", @page ),
				'user_id' => $user_id,
			}
		);
	}
	$c->stash->{'template'} = 'message.tt2';
	$c->stash->{'title'}    = "automatic message";
	$c->stash->{'message'}  =
	  "The start page was set to '" . join( "/", @page, $not_necessary) . "\n";
	$c->session->{'back_2'} = "/" . join( "/", @page,$not_necessary );
}

sub Set_Start_Page : Local : Form {
	my ( $self, $c, $username ) = @_;
	unless ( defined $username ) {
		$username =  $c->user();
	}
	elsif ( ! $self->__check_user( $c, 'admin', 1 ) ) {
		$username =  $c->user();
	}
	if ( $c->user() eq $username ) {
		$self->__check_user($c);
	}
	## Now only the admin might change the start site for someone else!
	my $hash = $c->model('Start_Page')->get_data_table_4_search(
		{
			'search_columns' => [ ref( $c->model('Start_Page') ) . '.*' ],
			'where'          => [ [ 'username', '=', 'my_value' ] ]
		},
		$username
	)->get_line_asHash(0);

#Carp::confess ( root::get_hashEntries_as_string ( $hash , 3 , "I need to know the damn has keys!" ));
	$c->stash->{'title'} = "Set the start page";
	$c->stash->{'text'}  =
"Remember, that I do not need the server name, only the path on the server!\n";
	$c->stash->{'text'} .= "Admin please remember, that you are changing the start page for the user '$username'!\n";
	if ( defined $hash ) {
		$self->{'form_array'} = [
			{
				'type'  => 'text',
				'label' => 'new start-page for user ' . $username,
				'name'  => 'page',
				'value' => $hash->{'start_page.page'}
			}
		];
	}
	else {
		$self->{'form_array'} = [
			{
				'type'  => 'text',
				'label' => 'new start-page for user ' . $username,
				'name'  => 'page'
			}
		];
	}
	foreach my $value ( @{ $self->{'form_array'} } ) {
		$self->formbuilder->field(%$value);
	}
	if ( $self->formbuilder->submitted() ) {
		my $dataset = $self->__process_returned_form($c);
		my $user_id = $c->model('ACL')->Get_id_for_name($username);
		if ( defined $hash ) {
			unless ( $dataset->{'page'} =~ m/\w/ ) {
				$c->model('Start_Page')->delete_entry(
					{
						'user_id' => $user_id,
						'id'      => $hash->{'start_page.id'}
					}
				);
			}
			else {
				$dataset->{'id'} =
				  $hash->{ ref( $c->model('Start_Page') ) . '.id' };
				$c->model('Start_Page')->UpdateDataset(
					{
						'page'    => $dataset->{'page'},
						'user_id' => $user_id,
						'id'      => $hash->{'start_page.id'}
					}
				);
			}
		}
		else {
			$dataset->{'user'} = { 'username' => $username };
			$c->model('Start_Page')->AddDataset($dataset);
		}
		$c->res->redirect("/");
		$c->detach();
	}

	$c->stash->{'template'} = 'LabBook.tt2';
}

sub Change_go_there : Local : Form {
	my ( $self, $c, @args ) = @_;
	$self->__check_user( $c, 'admin' );

	#unless ( $c->model("ACL")->user_has_role( $c->user, 'admin' ) ) {
	#	$c->res->redirect( $c->uri_for('/access_denied') );
	#	$c->detach();
	#}
	$c->stash->{'sidebar'} =
	  $c->model('LinkList')->GetSidbar_4( ref($self), $c->user, $c );
	$self->{'form_array'} = [];
	$self->Add_add_form(
		$c,
		{
			'db_obj'              => $c->model("LinkList"),
			'redirect_on_success' => '/administration/Change_go_there/',
			'come_from'           => "/add_2_model/index/"
		}
	);
	foreach my $hash ( @{ $self->{'form_array'} } ) {
		$self->formbuilder->field(%$hash);
	}
	$c->stash->{'title'} = "Add a link to the go there section";
	$c->stash->{'text'}  =
"Please consider, that you can not delete one of these links later on!<BR>\n";
	$c->stash->{'template'} = 'LabBook.tt2';
}

sub AddUser : Local : Form {
	my ( $self, $c, @args ) = @_;
	$self->__check_user( $c, 'admin' );

	#unless ( $c->model("ACL")->user_has_role( $c->user, 'admin' ) ) {
	#	$c->res->redirect( $c->uri_for('/access_denied') );
	#	$c->detach();
	#}
	my $temp;
	$c->stash->{'sidebar'} =
	  $c->model('LinkList')->GetSidbar_4( ref($self), $c->user, $c );
	my $model = $c->model('ACL')->get_as_object();
	$self->{'form_array'} = [ $model->get_formdef_array() ];

	foreach my $hash ( @{ $self->{'form_array'} } ) {
		$self->formbuilder->field(%$hash);
	}
	$c->stash->{'title'} = "Add a Scientist";
	$c->stash->{'text'}  =
	    "Please set all information for the scientist<BR>\n";

	if ( $self->formbuilder->submitted() ) {
		my $dataset = $self->__process_returned_form($c);
		$model->process_my_values($dataset);
		$c->res->redirect(
			$c->uri_for('/administration/Admin_User_Interface/') );
		$c->detach();

		#$c->model("ACL")->AddDataset($dataset);
	}

	$c->stash->{'template'} = 'Form.tt2';

#$c->response->body('Matched Genexpress_catalist::Controller::Administration in Administration.');
}

sub removeUser : Local : Form {
	my ( $self, $c ) = @_;
	$self->__check_user( $c, 'admin' );

	#unless ( $c->model("ACL")->user_has_role( $c->user, 'admin' ) ) {
	#	$c->res->redirect('/access_denied');
	#	$c->detach();
	#}
	$c->response->body('Not implemented!');
}

=head1 AUTHOR

Stefan Lang

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
