#!perl

use strict;
use warnings;

use Test::More (tests => 13);

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $fakes     = dir( $Bin, qw(data fakes) );
my $source    = URI->new("file://$fakes");
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

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL1);
$t->result_ok( $pinto->run_actions() );

#------------------------------------------------------------------------------
# Removing the local dist...

$pinto->new_action_batch();
$pinto->add_action('Remove', dist_name => $dist_name, author => $LOCAL2);
$t->result_not_ok( $pinto->run_actions() );

like($t->bufferstr(), qr/$LOCAL2\/$dist_name does not exist/,
     'Cannot remove dist owned by another author');

$pinto->new_action_batch();
$pinto->add_action('Remove', dist_name => $dist_name, author => $LOCAL1 );
$t->result_ok( $pinto->run_actions() );

$t->dist_not_exists_ok( $dist_name, $LOCAL1 );
$t->path_not_exists_ok( [qw( authors id L LO LOCAL1 CHECKSUMS)] );
$t->path_not_exists_ok( [qw( authors id L LO LOCAL1 )] );
$t->path_not_exists_ok( [qw( authors id L LO )] );
$t->path_not_exists_ok( [qw( authors id L )] );
$t->path_exists_ok( [qw( authors id )] );
$t->package_not_loaded_ok('Foo', $dist_name, $LOCAL1 );
