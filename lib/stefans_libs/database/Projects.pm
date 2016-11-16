package stefans_libs::database::Projects;


#  Copyright (C) 2010 Stefan Lang

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

use stefans_libs::database::variable_table;
use base variable_table;

use stefans_libs::database::scientistTable;

##use some_other_table_class;

use strict;
use warnings;


sub new {

    my ( $class, $dbh, $debug ) = @_;
    
    Carp::confess ("$class : new -> we need a acitve database handle at startup!, not "
	  . ref($dbh))
	  unless ( ref($dbh) =~ m/::db$/ );

    my ($self);

    $self = {
        debug => $debug,
        dbh   => $dbh
    };

    bless $self, $class if ( $class eq "stefans_libs::database::Projects" );
    $self->init_tableStructure();
    
    my $tmp = $self-> get_data_table_4_search( {
        	'search_columns' => ['projects.id'],
        	'where' => [ ],
        	'order_by' => [['nothing', '-', 'projects.id']],
        	'limit' => 'limit 1'
        },);
	unless ( $tmp->Rows() ) {
		$self->{'next_id'} = 1;
	}else {
		$self->{'next_id'} = @{@{$tmp->{'data'}}[0]}[0] + 1;
	}
    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "projects";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'name',
               'type'         => 'VARCHAR (20)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'description',
               'type'         => 'TEXT',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'owner',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => '',
               'data_handler' => 'scientistTable',
               'link_to'      => 'id',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'md5_sum',
               'name'        => 'md5_sum',
               'type'        => 'VARCHAR (32)',
               'NULL'        => '1',
               'description' => '',
          }
     );

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = ['name'] ;
	 $self->{'Group_to_MD5_hash'} = ['description'];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'scientistTable'} = scientistTable->new($self->{'dbh'}, $self->{'debug'});
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}



sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	if ( ! defined $dataset->{'name'} and  ! defined $dataset->{'projects.name'} ){
		$dataset->{'name'} = "LUNBIO".sprintf("%014d", $self->{'next_id'} );
		#warn "I have created the name as '".$dataset->{'name'}."' using the next_id $self->{'next_id'}\n";
		$self->{'next_id'} ++;
	}
	
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub get_project_name_4_id {
	my ( $self, $name ) = @_;
	my $sth =
	  $self->dbh()
	  ->prepare(
		'select name from ' . $self->TableName() . " where id = ?" );
	$sth->execute($name);
	my $id;
	$sth->bind_columns( \$id );
	$sth->fetch();
	unless ( defined $id ) {
		warn 'we got no data for the search :'
		  . 'select username from '
		  . $self->TableName()
		  . " where username = '$name';\n";
	}
	return $id;
}

sub user_has_access {
	my ( $self, $projectName, $username ) = @_;
	my $add= ref($self).'.';
	my $t = $self->get_data_table_4_search( {
	   	'search_columns' => [$add.'id'],
	   	'where' => [ [$add.'name', '=', 'my_value'], [ref($self->{'data_handler'}->{'scientistTable'}).'.username', '=', 'my_value'] ],
	   },$projectName, $username );
	return $t->Rows();
}

#sub INSERT_INTO_DOWNSTREAM_TABLES {
#	my ( $self, $dataset ) = @_;
#	 .= '';
#	return 1;
#}
#
#sub post_INSERT_INTO_DOWNSTREAM_TABLES {
#	my ( $self, $id, $dataset ) = @_;
#	$self->{'error'} .= '';
#	return 1;
#}
#
#sub CHECK_BEFORE_UPDATE{
#	my ( $self, $dataset ) = @_;
#
#	$self->{'error'} .= ref($self) . "::DO_ADDITIONAL_DATASET_CHECKS \n"
#	  unless (1);
#
#	return 0 if ( $self->{'error'} =~ m/\w/ );
#	return 1;
#}


sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
