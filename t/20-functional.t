#!perl

use strict;
use warnings;

use Test::File;
use Test::More (tests => 36);

use File::Temp;
use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Pinto;
use Pinto::Creator;
use Pinto::Tester;

#------------------------------------------------------------------------------

my $repos     = dir( File::Temp::tempdir(CLEANUP => 1) );
my $fakes     = dir( $Bin, qw(data fakes) );
my $source    = URI->new("file://$fakes");
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );
my $dist_name = 'FooOnly-0.01.tar.gz';
my $archive = $auth_dir->file($dist_name);

#------------------------------------------------------------------------------
# Creation...

my $creator = Pinto::Creator->new( repos => $repos );
$creator->create();

my $pinto     = Pinto->new(out => \my $buffer, repos => $repos, source => $source, verbose => 3);
my $t         = Pinto::Tester->new(pinto => $pinto);

#------------------------------------------------------------------------------
# Addition...

# Make sure we have clean slate
$t->package_not_loaded_ok( 'Foo' );
$t->dist_not_exists_ok( 'AUTHOR', $dist_name );

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => 'AUTHOR');
$pinto->run_actions();

$t->dist_exists_ok( 'AUTHOR', $dist_name );
$t->package_indexed_ok('Foo', 'AUTHOR', '0.01');

#-----------------------------------------------------------------------------
# Addition exceptions...

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => 'AUTHOR');
$pinto->run_actions();

like($buffer, qr/$dist_name already exists/, 'Cannot add same dist twice');

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => 'CHAUCER');
$pinto->run_actions();

like($buffer, qr/Only author AUTHOR can update/, 'Cannot add package owned by another author');

$pinto->new_action_batch();
$pinto->add_action('Add', archive => 'none_such', author => 'AUTHOR');
$pinto->run_actions();

like($buffer, qr/none_such does not exist/, 'Cannot add nonexistant archive');

#------------------------------------------------------------------------------
# Removal...

$pinto->new_action_batch();
$pinto->add_action('Remove', dist_name => $dist_name, author => 'CHAUCER');
$pinto->run_actions();

like($buffer, qr/CHAUCER\/$dist_name does not exist/, 'Cannot remove dist owned by another author');

$pinto->new_action_batch();
$pinto->add_action('Remove', dist_name => $dist_name, author => 'AUTHOR' );
$pinto->run_actions();

$t->dist_not_exists_ok( 'AUTHOR', $dist_name );
$t->path_not_exists_ok( [qw( authors id A AU AUTHOR )] );
$t->path_not_exists_ok( [qw( authors id A AU )] );
$t->path_not_exists_ok( [qw( authors id A )] );
$t->package_not_indexed_ok( 'Foo' );

# Adding again, with different author...
$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => 'CHAUCER');
$pinto->run_actions();

$t->dist_exists_ok( 'CHAUCER', $dist_name );
$t->package_indexed_ok('Foo', 'CHAUCER', '0.01');

#------------------------------------------------------------------------------
# Updating...


$pinto->new_action_batch();
$pinto->add_action('Update');
$pinto->run_actions();

$t->dist_exists_ok( 'LOCAL', 'Foo-Bar-Baz-0.03.tar.gz' );
$t->dist_exists_ok( 'LOCAL', 'BarAndBaz-0.04.tar.gz' );

$t->package_indexed_ok( 'Foo::Bar::Baz', 'LOCAL', '0.03' );
$t->package_indexed_ok( 'Bar', 'LOCAL', '0.04', );
$t->package_indexed_ok( 'Baz', 'LOCAL', '0.04', );
$t->package_indexed_ok( 'Foo', 'CHAUCER', '0.01' );

$t->dist_not_exists_ok( 'LOCAL', 'FooOnly-0.01.tar.gz' );

$t->dist_exists_ok( 'LOCAL', 'Fee-0.02_1.tar.gz' );
$t->package_not_indexed_ok( 'Fee' );
