#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, @roles, $email, $name, $position, $username, $workgroup, $pw, );

my $exec = $plugin_path . "/../bin/addUser.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/addUser";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}


my $cmd =
    "perl -I $plugin_path/../lib  $exec.pl "
. " -roles " . join(' ', @roles )
. " -email " . $email 
. " -name " . $name 
. " -position " . $position 
. " -username " . $username 
. " -workgroup " . $workgroup 
. " -pw " . $pw 
. " -debug";
#print "\$exp = ".root->print_perl_var_def($value ).";\n