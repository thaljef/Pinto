#!perl

use strict;
use warnings;

use Test::File;
use Test::More (tests => 74);

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
my $archive   = $auth_dir->file($dist_name);

# A couple local authors...
my $LOCAL1 = 'LOCAL1';
my $LOCAL2 = 'LOCAL2';

# This is a bit confusing.  CPAN::Faker creates all the packages under
# the the author 'LOCAL'.  But we are treating the fake CPAN as a
# foreign source.  So the author seems "foreign" to Pinto, but is
# "local" to the fake CPAN.  Just pretend you didn't see this next line.
my $FOREIGN = 'LOCAL';

#------------------------------------------------------------------------------
# Creation...

my $creator = Pinto::Creator->new( repos => $repos );
$creator->create();

my $pinto = Pinto->new(out => \my $buffer, repos => $repos, source => $source, verbose => 3);
my $t     = Pinto::Tester->new(pinto => $pinto);

# Make sure we have clean slate
$t->package_not_loaded_ok('Foo', $dist_name, $LOCAL1);
$t->dist_not_exists_ok($dist_name, $LOCAL1);

#------------------------------------------------------------------------------
# Adding a local dist...

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL1);
$t->result_ok( $pinto->run_actions() );

$t->dist_exists_ok( $dist_name, $LOCAL1 );
$t->path_exists_ok( [qw( authors id L LO LOCAL1 )] );
$t->path_exists_ok( [qw( authors id L LO )] );
$t->path_exists_ok( [qw( authors id L )] );

$t->package_loaded_ok('Foo', $dist_name, $LOCAL1, '0.01');
$t->package_is_latest_ok('Foo', $dist_name, $LOCAL1);

#-----------------------------------------------------------------------------
# Addition exceptions...

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL1);
$t->result_not_ok( $pinto->run_actions() );

like($buffer, qr/$dist_name already exists/,
     'Cannot add same dist twice');

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL2);
$t->result_not_ok( $pinto->run_actions() );

like($buffer, qr/Only author $LOCAL1 can update package Foo/,
     'Cannot add package owned by another author');

$pinto->new_action_batch();
$pinto->add_action('Add', archive => 'none_such', author => $LOCAL1);
$t->result_not_ok( $pinto->run_actions() );

like($buffer, qr/none_such does not exist/,
     'Cannot add nonexistant archive');

my $lower = $auth_dir->file('FooOnly-0.009.tar.gz');
$pinto->new_action_batch();
$pinto->add_action('Add', archive => $lower, author => $LOCAL1);
$t->result_not_ok( $pinto->run_actions() );

like($buffer, qr/Foo-0.009 has lower version than existing package Foo-0.01/,
     'Cannot add package with lower version number');

#------------------------------------------------------------------------------
# Removing local dist...

$pinto->new_action_batch();
$pinto->add_action('Remove', dist_name => $dist_name, author => $LOCAL2);
$t->result_not_ok( $pinto->run_actions() );

like($buffer, qr/$LOCAL2\/$dist_name does not exist/,
     'Cannot remove dist owned by another author');

$pinto->new_action_batch();
$pinto->add_action('Remove', dist_name => $dist_name, author => $LOCAL1 );
$t->result_ok( $pinto->run_actions() );

$t->dist_not_exists_ok( $dist_name, $LOCAL1 );
$t->path_not_exists_ok( [qw( authors id L LO LOCAL1 )] );
$t->path_not_exists_ok( [qw( authors id L LO )] );
$t->path_not_exists_ok( [qw( authors id L )] );
$t->package_not_loaded_ok('Foo', $dist_name, $LOCAL1 );

#------------------------------------------------------------------------------
# Adding local dist again, with different author...

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL2);
$t->result_ok( $pinto->run_actions() );

$t->dist_exists_ok( $dist_name, $LOCAL2 );
$t->package_loaded_ok('Foo', $dist_name, $LOCAL2, '0.01');
$t->package_is_latest_ok('Foo', $dist_name, $LOCAL2);

#------------------------------------------------------------------------------
# Updating from a foreign repository...



$pinto->new_action_batch();
$pinto->add_action('Update');
$t->result_ok( $pinto->run_actions() );

$t->dist_exists_ok('BarAndBaz-0.04.tar.gz',   $FOREIGN);
$t->dist_exists_ok('Fee-0.02_1.tar.gz',       $FOREIGN);
$t->dist_exists_ok('FooAndBar-0.02.tar.gz',   $FOREIGN);
$t->dist_exists_ok('Foo-Bar-Baz-0.03.tar.gz', $FOREIGN);

$t->package_loaded_ok( 'Bar',             'BarAndBaz-0.04.tar.gz', $FOREIGN, '0.04'    );
$t->package_loaded_ok( 'Baz',             'BarAndBaz-0.04.tar.gz', $FOREIGN, '0.04'    );
$t->package_loaded_ok( 'Fee',             'Fee-0.02_1.tar.gz',     $FOREIGN, '0.02_1'  );
$t->package_loaded_ok( 'Foo',             'FooAndBar-0.02.tar.gz', $FOREIGN, '0.02'    );
$t->package_loaded_ok( 'Foo::Bar::Baz', 'Foo-Bar-Baz-0.03.tar.gz', $FOREIGN, '0.03'    );

$t->package_is_latest_ok(  'Foo',  'FooOnly-0.01.tar.gz',   $LOCAL2 );
$t->package_is_latest_ok(  'Bar',  'BarAndBaz-0.04.tar.gz', $FOREIGN );
$t->package_is_latest_ok(  'Baz',  'BarAndBaz-0.04.tar.gz', $FOREIGN );

$t->package_not_latest_ok( 'Foo',  'FooAndBar-0.02.tar.gz', $FOREIGN );
$t->package_not_latest_ok( 'Fee',  'Fee-0.02_1.tar.gz',     $FOREIGN );

#------------------------------------------------------------------------------
# Adding a local version of an existing foreign package...

$dist_name = 'BarAndBaz-0.04.tar.gz';
$archive   =  $auth_dir->file($dist_name);

$pinto->new_action_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL2);
$pinto->run_actions();

$t->dist_exists_ok( $dist_name, $LOCAL2 );
$t->package_loaded_ok('Bar', $dist_name, $LOCAL2, '0.04');
$t->package_loaded_ok('Baz', $dist_name, $LOCAL2, '0.04');

$t->package_is_latest_ok('Bar', $dist_name, $LOCAL2);
$t->package_is_latest_ok('Baz', $dist_name, $LOCAL2);

$t->package_not_latest_ok('Bar', $dist_name, $FOREIGN);
$t->package_not_latest_ok('Baz', $dist_name, $FOREIGN);

#------------------------------------------------------------------------------
# After removing our local version, the foreign version should become latest...

$pinto->new_action_batch();
$pinto->add_action('Remove', dist_name => $dist_name, author => $LOCAL2 );
$pinto->run_actions();

$t->package_not_loaded_ok('Bar', $dist_name, $LOCAL2);
$t->package_not_loaded_ok('Baz', $dist_name, $LOCAL2);
$t->dist_not_exists_ok($dist_name, $LOCAL2);

$t->package_is_latest_ok('Bar', $dist_name, $FOREIGN);
$t->package_is_latest_ok('Baz', $dist_name, $FOREIGN);
