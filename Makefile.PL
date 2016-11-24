#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'BigData_Webinterface';
all_from 'lib/BigData_Webinterface.pm';

requires 'Catalyst::Runtime' => '5.90103';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::ActionRole';
requires 'Moose';
requires 'Catalyst::ActionRole::RequireSSL'; 
requires 'DBI' => 0;
requires 'DBD::SQLite' => 0;
requires 'Catalyst::ActionRole::NoSSL';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats

requires 'stefans_libs-RInterface' => 0;
test_requires 'Test::More' => '0.88';


catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll();
