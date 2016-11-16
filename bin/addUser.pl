#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-11-14 Stefan Lang

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

=head1  SYNOPSIS

    addUser.pl
       -username       :<please add some info!>
       -name       :<please add some info!>
       -workgroup       :<please add some info!>
       -position       :<please add some info!>
       -email       :<please add some info!>
       -pw       :<please add some info!>
       -roles     :<please add some info!> you can specify more entries to that


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  add the first admin user to the database

  To get further help use 'addUser.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use stefans_libs::database::scientistTable;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,      $debug,    $database, $username, $name,
	$workgroup, $position, $email,    $pw,       @roles
);

Getopt::Long::GetOptions(
	"-username=s"  => \$username,
	"-name=s"      => \$name,
	"-workgroup=s" => \$workgroup,
	"-position=s"  => \$position,
	"-email=s"     => \$email,
	"-pw=s"        => \$pw,
	"-roles=s{,}"  => \@roles,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $username ) {
	$error .= "the cmd line switch -username is undefined!\n";
}
unless ( defined $name ) {
	$error .= "the cmd line switch -name is undefined!\n";
}
unless ( defined $workgroup ) {
	$error .= "the cmd line switch -workgroup is undefined!\n";
}
unless ( defined $position ) {
	$error .= "the cmd line switch -position is undefined!\n";
}
unless ( defined $email ) {
	$error .= "the cmd line switch -email is undefined!\n";
}
unless ( defined $pw ) {
	$error .= "the cmd line switch -pw is undefined!\n";
}
unless ( defined $roles[0] ) {
	$error .= "the cmd line switch -roles is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	print "$errorMessage.\n";
	pod2usage( q(-verbose) => 1 );
}

my ($task_description);

$task_description .= 'perl ' . $plugin_path . '/addUser.pl';
$task_description .= " -username '$username'" if ( defined $username );
$task_description .= " -name '$name'" if ( defined $name );
$task_description .= " -workgroup '$workgroup'" if ( defined $workgroup );
$task_description .= " -position '$position'" if ( defined $position );
$task_description .= " -email '$email'" if ( defined $email );
$task_description .= " -pw '$pw'" if ( defined $pw );
$task_description .= ' -roles "' . join( '" "', @roles ) . '"'
  if ( defined $roles[0] );

## Do whatever you want!

my $ACL = scientistTable->new();

my $id = $ACL->AddDataset(
	{
		username      => $username,
		name          => $name,
		workgroup     => $workgroup,
		position      => $position,
		email         => $email,
	}
);

map {$ACL->AddRole( { 'username' => $username, 'role' => $_ })} @roles;


( $pw ) = $ACL->_hash_pw($username,$pw);

$ACL -> UpdateDataset( { 'id' => $id, pw => $pw } );


print "The new user has the ID $id\n";