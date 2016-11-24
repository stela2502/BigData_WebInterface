package BigData_Webinterface::controller;


use Moose::Role;

=head1 LICENCE

  Copyright (C) 2016-11-16 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

BigData_Webinterface::controller

=head1 DESCRIPTION

a set of controller extensions implemented as moose::role

=head2 depends on


=cut


=head1 METHODS

=head2 new ( $hash )

new returns a new object reference of the class BigData_Webinterface::controller.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut

sub input_sec_check {
	my ( $self, $str ) = @_;
	## all " and ' have to be removed unless in a regexp
	## script html entries have to be blocked
	#$str =~ s/(?<!\\)["']//g;
    $str =~ s/<script .*<\/script>//g;
   # $str =~ s/[\n\r]/ /g;
    $str =~ s/;/ /g;
    return $str;
}

sub __process_returned_form {
	my ( $self, $c, $projectName ) = @_;
	my ( $dataset, @data );
	## check the temp path and store that in the cookie
	if ( defined $projectName ){
	my $path = $c->session_path($projectName);    #unless ( defined $c->session->{'path'} );
	unless ( -d $path ) {
		Carp::confess( "The session path '"
			  . $c->session->{'path'}
			  . "' has not been created!\n$!\n" );
	}
	for my $field ( $c->req->uploads ) {
		if ( ref($field) eq "HASH" ) {
			foreach my $type ( keys %$field ) {    ## multiple file options
				$dataset->{$type} = [];
				foreach my $upload (
					map {
						if   ( ref($_) eq "ARRAY" ) { @$_ }
						else                        { $_ }
					} $field->{$type}
				  )
				{
					my $filename = $upload->basename;
					warn "I copy $filename to ". $path . "data/$filename\n";
					unless (
						$upload->copy_to( $path . "data/$filename" )
					  )
					{
						Carp::confess(
"I tried to upload the field named '$field->{'name'}' "
							  . "which should be a file, ($path/data/$filename) but I got no file object but ("
							  . $upload . ")!\n"
							  . "A frequent error is to not use the 'post' methood for the page (missing the line '$c->form->method('post');')\n"
						);
					}
					else {
						push(
							@{ $dataset->{$type} },
							root->filemap( $path . $filename )
						);
					}

				}
			}
		}
	}
	}
	foreach my $field ( $c->form->fields ) {
		if ( defined( $field->{'type'} ) && $field->{'type'} eq "file" ) {
			next;
		}
		elsif ( $field->{'multiple'} ) {
			@data = $c->form->field($field);
			$dataset->{$field} = [map { $self->input_sec_check($_) } @data];
		}
		else {
			@data = $c->form->field($field);
			$dataset->{$field} = $self->input_sec_check($data[0]);
		}
	}
	unless ( keys %$dataset > 0 ) {
		## probably a re-read of the data?
		return $self->{'form_store'}
		  if ( ref( $self->{'form_store'} ) eq "HASH" );
		return $dataset;
	}
	$self->{'form_store'} = { map { $_ => $dataset->{$_} } keys %$dataset };
	return $dataset;
}

sub Script {
	my ( $self, $c, $add ) = @_;
	$c->stash->{'script'} ||= '';
	if ( defined $add ) {
		foreach ( split( "\n", $add ) ) {
			my $check = $_;
			$check =~ s/\(/\\(/g;
			$check =~ s/\)/\\)/g;
			$check =~ s/\}/\\}/g;
			$check =~ s/\{/\\{/g;
			#warn "EnableFiles::Script:". $check."\n";
			$c->stash->{'script'} .= $_ . "\n"
			  unless ( $c->stash->{'script'} =~ m/$check/ );
		}
	}
	$c->stash->{'script'};
}

=head2 __check_user ($c, $REQUIRED_ROLE)

This function cecks the rights of the users. First, whether the user is logged in.
If he/she is logged in and the function also requires an role the role is checked.

If the $REQUIRED_ROLE is an array of roles, any of the roles is sufficient to access the page.

=cut

sub __check_user {
	my ( $self, $c, $REQUIRED_ROLE, $return_0 ) = @_;
	$c ->cookie_check();
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


=head2 __user_has_access ( $c, $projectName )

If the user has NO access to the project an error message will be shown.

=cut

sub __user_has_access {
	my ( $self, $c, $projectName ) =@_;
	unless ( defined $projectName ) {
		$c->res->redirect('/projects/index/');
		$c->detach();
	}
	unless ( $c->model('Project') -> user_has_access ( $c, $projectName)) {
		$c->res->redirect('/access_denied/You must not access this project/');
		$c->detach();
	}
	return 1;
}

sub file_upload {
	my ( $self, $c, $projectName, $processed_form ) = @_;
	
	#Carp::cluck( "\n\n\nfile_upload:\n$projectName\n\n" );
	
	my $session_hash = $self->init_file_cookie($c, $projectName);
	unless ($session_hash) {
		return 0;
	}
	my $files = 0;
	my $unique;
	$self->{'new_files'} = 0;
	my $filetype = 'files';

	for ( my $i = @{ $session_hash->{$filetype} } ; $i >= 0 ; $i-- ) {
		next unless ( defined @{ $session_hash->{$filetype} }[$i] );
		unless ( -f @{ $session_hash->{$filetype} }[$i]->{'total'} ) {
			splice( @{ $session_hash->{$filetype} }, $i, 1 );
		}
	}

	$unique = { map { $_->{'filename'} => 1 } @{ $session_hash->{$filetype} } };
	if ( defined $processed_form->{$filetype} ) {
		## I might have some arrays here
		foreach my $new_file (
			map {
				if   ( ref($_) eq "ARRAY" ) { @$_ }
				else                        { $_ }
			} $processed_form->{$filetype}
		  )
		{
			my $tmp;
			if ( -f $new_file->{'total'}
				and !$unique->{ $new_file->{'filename'} } )
			{
				($new_file) =
				  $self->file_format_fixes( $c, $new_file, $unique, $filetype );
				push( @{ $session_hash->{$filetype} }, $new_file );
				$self->{'new_files'} = 1;
			}
		}
	}
	$files += @{ $session_hash->{$filetype} };
	$c->stash->{$filetype} = $session_hash->{$filetype};
	return $files;
}

sub init_file_cookie {
	my ( $self, $c, $projectName, $force ) = @_;
	$force ||= 0;
	my $session_hash = $c->session();
	unless ( defined $session_hash ) {
		return 0;
	}
	if ($force) {
		map { $session_hash->{$_} = [] } 'files';
	}
	else {
		map {
			$session_hash->{$_} = []
			  unless ( ref( $session_hash->{$_} ) eq "ARRAY" )
		} 'files';
		if ( defined  @{$session_hash->{'files'}}[0] ){
			$session_hash->{'files'} = [] unless ( ref(@{$session_hash->{'files'}}[0]) eq "HASH");
		}
		my $path = $c->session_path($projectName)."data/";
		#warn "\n\n\ninit_file_cookie\n$path\n$projectName\n\n";
		my $already_there = { map { $_->{'total'} => 1 } map{ unless ( ref($_) eq "HASH") { root->filemap($_)} else { $_ } } @{ $session_hash->{'files'} } };
		opendir( DIR, "$path" )
		  or Carp::confess("$path: I could not open the project path '$path'\n$!");
		map {
			push( @{ $session_hash->{files} }, root->filemap($path . $_) )
			  unless ( $already_there->{ $path . $_ } )
		} grep ( /^\w/, readdir(DIR) );
		closedir(DIR);
	}
	return $session_hash;
}

sub file_format_fixes {
	my ( $self, $c, $filename, $unique, $filetype ) = @_;
	## to get rid of this line ending problems:
	unless ( ref($filename) eq "HASH" ) {
		$filename = root->filemap($filename);

	}

	my $outfile = $filename;
	$outfile = root->filemap(
		join( "/",
			$filename->{'path'},
			join( "_", split( /\s+/, $filename->{'filename'} ) ) )
	);
	unless ( $outfile->{'total'} eq $filename->{'total'} ) {
		system("cp '$filename->{'total'}' '$outfile->{'total'}'");
		$filename = $outfile;
		$unique->{ $filename->{'filename'} } = 1;
	}

	system("/usr/bin/dos2unix -q '$filename->{'total'}'");
	system("/usr/bin/dos2unix -q -c mac '$filename->{'total'}'");

	## bloody hack to get rid of the stupid ...3","23,43","32.... format problems
	$self->__fix_file_problems( $filename->{'total'}, $filetype );

	return ($filename);
}

sub __fix_file_problems {
	my ( $self, $filename, $filetype ) = @_;
	open( OUT, ">$filename.mod" )
	  or
	  Carp::confess("I could not open the outfile '$filename.mod'\nError: $!");
	open( IN, "<$filename" );
	if ( $filetype eq "facsTable" ) {
		my $rep;
		## 1,000 == 1000 !!!!!!!
		while (<IN>) {
			foreach my $problem ( $_ =~ m/(["']-?\d+,\d+,?\d*["'])/g ) {
				$rep = $problem;
				$rep =~ s/["',]//g;
				$_   =~ s/$problem/$rep/;
			}
			print OUT $_;
		}
	}
	else {
		while (<IN>) {
			$_ =~ s/;"?(\d+)[\.,](\d+)"?;+?/;$1.$2;/g;
			$_ =~ s/;/,/g;
			print OUT $_;
		}
	}

	close(IN);
	close(OUT);
	system("mv '$filename.mod' '$filename'");
	return 1;
}




1;
