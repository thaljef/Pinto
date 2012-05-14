#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;

#------------------------------------------------------------------------------
# Test default config

my $t = Pinto::Tester->new;
my $pinto = $t->pinto;

$t->path_exists_ok( [qw(.pinto config pinto.ini)] );
$t->path_exists_ok( [qw(.pinto db pinto.db)] );
$t->path_exists_ok( [qw(modules 02packages.details.txt.gz)] );
$t->path_exists_ok( [qw(modules 03modlist.data.gz)] );
$t->path_exists_ok( [qw(authors 01mailrc.txt.gz)] );

is $pinto->config->devel,    0, 'Got default devel';
is $pinto->config->log_level,   'notice', 'Got default log_level';
is $pinto->config->sources,  'http://cpan.perl.org', 'Got default sources';

#------------------------------------------------------------------------------
# Test custom config

my $config = {sources => 'MySource', log_level => 'debug'};
$t = Pinto::Tester->new(init_args => $config);
$pinto = $t->pinto;

is $pinto->config->log_level,   'debug',  'Got custom log_level';
is $pinto->config->sources,  'MySource', 'Got custom source';

#------------------------------------------------------------------------------
# Test repository props

my $ver = $pinto->repos->get_property('pinto:schema_version');
is $ver, $Pinto::Schema::SCHEMA_VERSION, 'Got pinto:schema_version prop';

#------------------------------------------------------------------------------

done_testing;
