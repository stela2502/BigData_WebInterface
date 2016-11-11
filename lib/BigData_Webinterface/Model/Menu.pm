package BigData_Webinterface::Model::Menu;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

BigData_Webinterface::Model::Menu - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.


=encoding utf8

=head1 AUTHOR

Stefan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'foi' => []
	};

	bless $self, $class if ( $class eq "BigData_Webinterface::Model::Menu" );

	$self->Reinit();

	return $self;

}

sub Reinit {
	my ($self) = @_;
	$self->{'main2pos'} = {
		'Go To'           => 0,
		'Custom Grouping' => 1,
		'Download'        => 2,
		'Utilities'       => 3,
		'Clear all'       => 4,
	};
	$self->{'main'} = [
		[ 'Go To',           '/' ],
		[ 'Custom Grouping', '/regroup/index/' ],
		[ 'Download',        '/files/as_zip_file/' ],
		[ 'Utilities',       "/filemerger/" ],
		[ 'Clear all',       "/clear_all/" ]
	];
	$self->{'entries'} = [
		[
			[ "File Upload",          '/files/upload/' ],
			[ "Upload a zip file",    '/files/start_from_zip_file' ],
			[ "Analysis",             '/analyse/' ],
			[ "Error Report",         "/files/report_error/" ],
			[ "P values", "/pvalues/index/" ],

		],
		[
			[ "Sample Re-group",                   '/regroup/reorder/' ],
			[ "Sample Name Based Grouping", '/regroup/samplenames/' ],
			[ '1D Groups by Expression',    '/gene_group/' ],
			[
				"2D Groups by Expression (analysis run needed)", '/grouping_2d/'
			],
			[ "Gene Custom Order", '/complex_grouping/geneorder/' ],
			[ "Gene User Defined Grouping", '/complex_grouping/genegroup/' ],
			[ "Group Color Picker", '/complex_grouping/colorpicker/' ],
		],
		[], ## Download
		[
			[ "File Merger", '/filemerger/' ],
			[ 'Scrapbook',   '/scrapbook/index/' ],
			[ 'Random Forest start grouping', '/randomforest/calculate/'],
			[ 'Random Forest re-cluster', '/randomforest/newgrouping/'],
		],
		[	
			[ "renew R lib files", '/files/renew_rlib/' ],
		], ## clear_all
	];
	return $self;
}

=head2 Add ( $main, $link, $name )

Add and entry to the menue -> If you add a main entry you must give me the link for the main entry and NO name for the subentry!

=cut

sub Add {
	my ( $self, $main, $link, $name ) = @_;
	unless ( defined $self->{'main2pos'}->{$main} ) {
		$self->{'main2pos'}->{$main} = scalar( @{ $self->{'main'} } );
		push( @{ $self->{'main'} }, [ $main, $link ] );
		@{ $self->{'entries'} }[ $self->{'main2pos'}->{$main} ] = [];
		Carp::confess("You must not give me a name for the link!")
		  if ( defined $name );
	}
	else {
		push(
			@{ @{ $self->{'entries'} }[ $self->{'main2pos'}->{$main} ] },
			[ $name, $link ]
		);
	}
	return $self;
}

sub menu {
	my ( $self, $c ) = @_;
	my @values;
	my $path = $c->session_path();

	foreach ( @{ $self->{'foi'} } ) {

		#	Carp::confess ( "$path@$_[1]" );
		$self->Add( 'Download', '/files/index/' . $path . @$_[1], @$_[0] )
		  if ( -f $path . @$_[1] );
	}

	for ( my $i = 0 ; $i < @{ $self->{'main'} } ; $i++ ) {
		$_ = @{ $self->{'main'} }[$i];
		my @array;
		push(
			@values,
			{
				'link'    => $c->uri_for( @$_[1] ),
				'name'    => @$_[0],
				'objects' => \@array
			}
		);
		foreach ( @{ @{ $self->{'entries'} }[$i] } ) {
			push( @array,
				{ 'link' => $c->uri_for( @$_[1] ), 'name' => @$_[0] } );
		}
	}
	return @values;
}

__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

1;
