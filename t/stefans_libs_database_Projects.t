#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::Projects' }

my ( $value, @values, $exp );
my $obj = stefans_libs::database::Projects -> new();
is_deeply ( ref($obj) , 'stefans_libs::database::Projects', 'simple test of function stefans_libs::database::Projects -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


