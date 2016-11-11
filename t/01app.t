#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'BigData_Webinterface';

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
