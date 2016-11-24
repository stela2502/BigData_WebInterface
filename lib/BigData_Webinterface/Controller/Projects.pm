package BigData_Webinterface::Controller::Projects;
use Moose;
use namespace::autoclean;

use BigData_Webinterface::base_db_controler;

with 'BigData_Webinterface::controller';

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

BigData_Webinterface::Controller::Projects - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Local :Form {
    my ( $self, $c ) = @_;
	$self->__check_user($c);
	$self->{'form_array'}= [];
	push(
		@{ $self->{'form_array'} },
		{
			'comment' => 'project description',
			'name'    => 'description',
			'type'     => 'textarea',
			'cols'     => 35,
			'rows'     => 20,
			'value' => '',
			'required' => 1,
		}
	);
	$c->form->submit( ['Create Project'] );
	foreach ( @{ $self->{'form_array'} } ) {
		$c->form->field( %{$_} );
	}
	if  ( $c->form->submitted() && $c->form->validate() ){
		my $dataset = $self->__process_returned_form($c);
		$c->model('Project') ->  register_project ( $c, $dataset  );
	}
	
	my $data_table = $c->model('Project') -> {'projects'} -> get_data_table_4_search({
	'search_columns' => [ref($c->model('Project') -> {'projects'} ).'.name', ref($c->model('Project') -> {'projects'} ).'.description' ],
	'where' => [ ['username', '=', 'my_value'] ],
	}, $c->user());
	$data_table -> Remove_from_Column_Names ( ref($c->model('Project') -> {'projects'} ).'.' );
	$data_table -> HTML_modification_for_column ({'column_name' => 'name', 'colsub' => 
		sub {
			my ( $self, $value, $this_hash, $type ) = @_;
			if ( $type eq "td" ){
				return "<$type><a href='".$c->uri_for("/rcontroll/index")."/$value'>$value</a></$type>";
			}else {
				return "<$type>$value</$type>";
			}
		} });
		 
	$c->stash->{'title'}    = "Please select a project to work with or create a new one (left side).";
	
	$c->stash->{'text'}     = $data_table -> GetAsHTML();
	$c->stash->{'template'} = 'Projects.tt2';

}



=encoding utf8

=head1 AUTHOR

Stefan Lang,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
