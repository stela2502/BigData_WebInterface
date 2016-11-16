#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'BigData_Webinterface::controller' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = BigData_Webinterface::controller -> new({'debug' => 1});
is_deeply ( ref($OBJ) , 'BigData_Webinterface::controller', 'simple test of function BigData_Webinterface::controller -> new() ');

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


