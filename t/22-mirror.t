#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $fakes     = dir( $Bin, qw(data fakepan repos a) );
my $source    = URI->new("file://$fakes");
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );

my $us   = 'US';     # The local author
my $them = 'LOCAL';  # The foreign author (CPAN::Faker assigns them all to 'LOCAL');

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new( creator_args => {sources => $source} );
my $pinto = $t->pinto();

$t->repository_empty_ok();

#------------------------------------------------------------------------------
# Updating from a foreign repository...

$pinto->new_batch();
$pinto->add_action('Mirror', source => $source);

$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$them/BarAndBaz-0.04.tar.gz/Bar-0.04",  1 );
$t->package_loaded_ok( "$them/BarAndBaz-0.04.tar.gz/Baz-0.04",  1 );
$t->package_loaded_ok( "$them/Fee-0.02_1.tar.gz/Fee-0.02_1",    0 );
$t->package_loaded_ok( "$them/FooAndBar-0.02.tar.gz/Foo-0.02",  1 );

#------------------------------------------------------------------------------
# Adding a local version of an existing foreign package...

my $dist    = 'BarAndBaz-0.04.tar.gz';
my $archive =  $auth_dir->file($dist);

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $us);

$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$us/$dist/Bar-0.04", 1 );
$t->package_loaded_ok( "$us/$dist/Baz-0.04", 1 );

# The foreign versions should no longer be latest
$t->package_loaded_ok( "$them/$dist/Bar-0.04",  0 );
$t->package_loaded_ok( "$them/$dist/Baz-0.04",  0 );

#------------------------------------------------------------------------------
# After removing our local version, the foreign version should become latest...

$pinto->new_batch();
$pinto->add_action('Remove', path => $dist, author => $us );

$t->result_ok( $pinto->run_actions() );
$t->package_not_loaded_ok( "$us/$dist/Bar-0.04" );
$t->package_not_loaded_ok( "$us/$dist/Baz-0.04" );

$t->package_loaded_ok( "$them/$dist/Bar-0.04",  1 );
$t->package_loaded_ok( "$them/$dist/Baz-0.04",  1 );

done_testing();
