#!perl

use strict;
use warnings;

use Test::File;
use Test::More (tests => 40);

use File::Temp;
use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Pinto;
use Pinto::Tester;

#------------------------------------------------------------------------------

my $repos     = dir( File::Temp::tempdir(CLEANUP => 1) );
my $fakes     = dir( $Bin, qw(data fakes) );
my $source    = URI->new("file://$fakes");
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );
my $dist_base = 'FooOnly-0.01.tar.gz';
my $dist_file = $auth_dir->file($dist_base);

my $pinto     = Pinto->new(out => \my $buffer, repos => $repos, source => $source, verbose => 3);
my $t         = Pinto::Tester->new(pinto => $pinto);
#------------------------------------------------------------------------------
# Creation...

$pinto->new_action_batch();
$pinto->add_action('Create')->run_actions();
$t->path_exists_ok( [qw(config pinto.ini)] );
$t->path_exists_ok( [qw(modules 02packages.details.txt.gz)] );
$t->path_exists_ok( [qw(modules 02packages.details.local.txt.gz)] );
$t->path_exists_ok( [qw(modules 03modlist.data.gz)] );
$t->path_exists_ok( [qw(authors 01mailrc.txt.gz)] );

#------------------------------------------------------------------------------
# Addition...

# Make sure we have clean slate
$t->package_not_indexed_ok( 'Foo' );
$t->dist_not_exists_ok( 'AUTHOR', $dist_base );

$pinto->new_action_batch();
$pinto->add_action('Add', dist => $dist_file, author => 'AUTHOR');
$pinto->run_actions();

$t->dist_exists_ok( 'AUTHOR', $dist_base );
$t->package_indexed_ok('Foo', 'AUTHOR', '0.01');

#-----------------------------------------------------------------------------
# Addition exceptions...

$pinto->new_action_batch();
$pinto->add_action('Add', dist => $dist_file, author => 'AUTHOR');
$pinto->run_actions();

like($buffer, qr/same distribution already exists/, 'Cannot add same dist twice');

$pinto->new_action_batch();
$pinto->add_action('Add', dist => $dist_file, author => 'CHAUCER');
$pinto->run_actions();

like($buffer, qr/Only author AUTHOR can update/, 'Cannot add package owned by another author');

$pinto->new_action_batch();
$pinto->add_action('Add', dist => 'none_such', author => 'AUTHOR');
$pinto->run_actions();

like($buffer, qr/does not exist/, 'Cannot add nonexistant dist');

#------------------------------------------------------------------------------
# Removal...

$pinto->new_action_batch();
$pinto->add_action('Remove', package => 'None::Such', author => 'AUTHOR');
$pinto->run_actions();

like($buffer, qr/is not in the local index/, 'Removing bogus package throws exception');

$pinto->new_action_batch();
$pinto->add_action('Remove', package => 'Foo', author => 'CHAUCER');
$pinto->run_actions();

like($buffer, qr/Only author AUTHOR can remove/, 'Cannot remove package owned by another author');

$pinto->new_action_batch();
$pinto->add_action('Remove', package => 'Foo', author => 'AUTHOR' );
$pinto->run_actions();

$t->dist_not_exists_ok( 'AUTHOR', $dist_base );
$t->path_not_exists_ok( [qw( authors id A AU AUTHOR )] );
$t->path_not_exists_ok( [qw( authors id A AU )] );
$t->path_not_exists_ok( [qw( authors id A )] );
$t->package_not_indexed_ok( 'Foo' );

# Adding again, with different author...
$pinto->new_action_batch();
$pinto->add_action('Add', dist => $dist_file, author => 'CHAUCER');
$pinto->run_actions();

$t->dist_exists_ok( 'CHAUCER', $dist_base );
$t->package_indexed_ok('Foo', 'CHAUCER', '0.01');

#------------------------------------------------------------------------------
# Updating...

$pinto->new_action_batch();
$pinto->add_action('Update', force => 1);
$pinto->run_actions();

$t->dist_exists_ok( 'LOCAL', 'Foo-Bar-Baz-0.03.tar.gz' );
$t->dist_exists_ok( 'LOCAL', 'BarAndBaz-0.04.tar.gz' );
$t->dist_not_exists_ok( 'LOCAL', 'FooOnly-0.01' );

$t->package_indexed_ok( 'Foo::Bar::Baz', 'LOCAL', '0.03' );
$t->package_indexed_ok( 'Bar', 'LOCAL', '0.04', );
$t->package_indexed_ok( 'Baz', 'LOCAL', '0.04', );
$t->package_indexed_ok( 'Foo', 'CHAUCER', '0.01' );
