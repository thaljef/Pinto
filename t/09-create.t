#!perl

use strict;
use warnings;

use Test::More (tests => 13);

use File::Temp;
use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Pinto;
use Pinto::Creator;
use Pinto::Tester;

#------------------------------------------------------------------------------
# Test default config

my $default_repos    = dir( File::Temp::tempdir(CLEANUP => 1) );
my $default_creator = Pinto::Creator->new( repos => $default_repos );
$default_creator->create();

my $pinto = Pinto->new(repos => $default_repos);
my $t = Pinto::Tester->new(pinto => $pinto);

$t->path_exists_ok( [qw(config pinto.ini)] );
$t->path_exists_ok( [qw(db pinto.db)] );
$t->path_exists_ok( [qw(modules 02packages.details.txt.gz)] );
$t->path_exists_ok( [qw(modules 03modlist.data.gz)] );
$t->path_exists_ok( [qw(authors 01mailrc.txt.gz)] );

is $pinto->config->nocleanup(), 0, 'Got default nocleanup';
is $pinto->config->noinit(),    0, 'Got default noinit';
is $pinto->config->store(),     'Pinto::Store', 'Got default store';
is $pinto->config->source(),    'http://cpan.perl.org', 'Got default source';

#------------------------------------------------------------------------------
# Test custom config

my $custom_repos = dir( File::Temp::tempdir(CLEANUP => 1) );
my $custom_creator = Pinto::Creator->new( repos => $custom_repos);
$custom_creator->create(noinit => 1, nocleanup => 1, store => 'MyStore', source => 'http://mysource');

my $custom_pinto = Pinto->new(repos => $custom_repos);

is $custom_pinto->config->nocleanup(), 1, 'Got custom nocleanup';
is $custom_pinto->config->noinit(),    1, 'Got custom noinit';
is $custom_pinto->config->store(),     'MyStore', 'Got custom store';
is $custom_pinto->config->source(),    'http://mysource', 'Got custom source';

#------------------------------------------------------------------------------
