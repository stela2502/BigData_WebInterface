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
	my ( $self, $c ) = @_;
	my ( $dataset, @data );
	## check the temp path and store that in the cookie
	$c->session_path();    #unless ( defined $c->session->{'path'} );
	unless ( -d $c->session->{'path'} ) {
		mkdir( $c->session->{'path'} )
		  or Carp::confess( "I could not create the path '"
			  . $c->session->{'path'}
			  . "'\n$!\n" );
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
					unless (
						$upload->copy_to( $c->session->{'path'} . "$filename" )
					  )
					{
						Carp::confess(
"I tried to upload the field named '$field->{'name'}' "
							  . "which should be a file, ("
							  . $c->session->{'path'}
							  . "/$filename) but I got no file object but ("
							  . $upload . ")!\n"
							  . "A frequent error is to not use the 'post' methood for the page (missing the line '$c->form->method('post');')\n"
						);
					}
					else {
						push(
							@{ $dataset->{$type} },
							root->filemap( $c->session->{'path'} . $filename )
						);
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


1;
