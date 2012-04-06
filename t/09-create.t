#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;

use Pinto::Tester;

#------------------------------------------------------------------------------
# Test default config

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();

$t->path_exists_ok( [qw(.pinto config pinto.ini)] );
$t->path_exists_ok( [qw(.pinto db pinto.db)] );
$t->path_exists_ok( [qw(modules 02packages.details.txt.gz)] );
$t->path_exists_ok( [qw(modules 03modlist.data.gz)] );
$t->path_exists_ok( [qw(authors 01mailrc.txt.gz)] );

is $pinto->config->devel(),    0, 'Got default devel';
is $pinto->config->noinit(),   0, 'Got default noinit';
is $pinto->config->log_level(),   'notice', 'Got default log_level';
is $pinto->config->store(),    'Pinto::Store::File',   'Got default store';
is $pinto->config->sources(),  'http://cpan.perl.org', 'Got default sources';

#------------------------------------------------------------------------------
# Test custom config

my $config = {noinit => 1, store => 'MyStore', sources => 'MySource'};
$t = Pinto::Tester->new(creator_args => $config);
$pinto = $t->pinto();

is $pinto->config->noinit(),    1, 'Got custom noinit';
is $pinto->config->store(),     'MyStore', 'Got custom store';
is $pinto->config->sources(),   'MySource', 'Got custom source';

#------------------------------------------------------------------------------

done_testing();
