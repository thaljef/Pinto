#!perl

use strict;
use warnings;

use Test::More (tests => 20);

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $fakes     = dir( $Bin, qw(data fakes) );
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );
my $dist_name = 'FooOnly-0.01.tar.gz';
my $archive   = $auth_dir->file($dist_name);

# A couple local authors...
my $LOCAL1 = 'LOCAL1';
my $LOCAL2 = 'LOCAL2';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();

# Make sure we have clean slate
$t->package_not_loaded_ok('Foo', $dist_name, $LOCAL1);
$t->dist_not_exists_ok($dist_name, $LOCAL1);

#------------------------------------------------------------------------------
# Adding a local dist...

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL1);
$t->result_ok( $pinto->run_actions() );

$t->dist_exists_ok( $dist_name, $LOCAL1 );
$t->path_exists_ok( [qw( authors id L LO LOCAL1 CHECKSUMS)] );
$t->path_exists_ok( [qw( authors id L LO LOCAL1 )] );
$t->path_exists_ok( [qw( authors id L LO )] );
$t->path_exists_ok( [qw( authors id L )] );

$t->package_loaded_ok('Foo', $dist_name, $LOCAL1, '0.01');
$t->package_is_latest_ok('Foo', $dist_name, $LOCAL1);

#-----------------------------------------------------------------------------
# Addition exceptions...

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL1);
$t->result_not_ok( $pinto->run_actions() );

like($t->bufferstr(), qr/$dist_name already exists/,
     'Cannot add same dist twice');

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL2);
$t->result_not_ok( $pinto->run_actions() );

like($t->bufferstr(), qr/Only author $LOCAL1 can update package Foo/,
     'Cannot add package owned by another author');

$pinto->new_batch();
$pinto->add_action('Add', archive => 'none_such', author => $LOCAL1);
$t->result_not_ok( $pinto->run_actions() );

like($t->bufferstr(), qr/none_such does not exist/,
     'Cannot add nonexistant archive');

my $lower = $auth_dir->file('FooOnly-0.009.tar.gz');
$pinto->new_batch();
$pinto->add_action('Add', archive => $lower, author => $LOCAL1);
$t->result_not_ok( $pinto->run_actions() );

like($t->bufferstr(), qr/Foo-0.009 has lower version than existing package Foo-0.01/,
     'Cannot add package with lower version number');

