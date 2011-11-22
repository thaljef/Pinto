#!perl

use strict;
use warnings;

use Test::More (tests => 43);

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $fakes     = dir( $Bin, qw(data fakepan repos) );
my $source    = URI->new("file://$fakes");
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );
my $dist_name = 'FooOnly-0.01.tar.gz';
my $archive   = $auth_dir->file($dist_name);

# A local author...
my $LOCAL1 = 'LOCAL1';

# This is a bit confusing.  CPAN::Faker creates all the packages under
# the author 'LOCAL'.  But we are treating the fake CPAN as a
# foreign source.  So the author seems "foreign" to Pinto, but is
# "local" to the fake CPAN.  Just pretend you didn't see this next line.
my $FOREIGN = 'LOCAL';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();

# Make sure we have clean slate
$t->package_not_loaded_ok('Foo', $dist_name, $LOCAL1);
$t->dist_not_exists_ok($dist_name, $LOCAL1);

#------------------------------------------------------------------------------
# Updating from a foreign repository...

$pinto->new_batch();
$pinto->add_action('Mirror', source => $source);
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

$t->package_is_latest_ok( 'Foo',  'FooAndBar-0.02.tar.gz', $FOREIGN );
$t->package_is_latest_ok( 'Bar',  'BarAndBaz-0.04.tar.gz', $FOREIGN );
$t->package_is_latest_ok( 'Baz',  'BarAndBaz-0.04.tar.gz', $FOREIGN );

# Developer release should never be latest
$t->package_not_latest_ok( 'Fee',  'Fee-0.02_1.tar.gz',    $FOREIGN );
like $t->bufferstr(), qr{L/LO/LOCAL/Fee-0.02_1.tar.gz will not be indexed};

#------------------------------------------------------------------------------
# Adding a local version of an existing foreign package...

$dist_name = 'BarAndBaz-0.04.tar.gz';
$archive   =  $auth_dir->file($dist_name);

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $LOCAL1);
$pinto->run_actions();

$t->dist_exists_ok( $dist_name, $LOCAL1 );
$t->package_loaded_ok('Bar', $dist_name, $LOCAL1, '0.04');
$t->package_loaded_ok('Baz', $dist_name, $LOCAL1, '0.04');

$t->package_is_latest_ok('Bar', $dist_name, $LOCAL1);
$t->package_is_latest_ok('Baz', $dist_name, $LOCAL1);

$t->package_not_latest_ok('Bar', $dist_name, $FOREIGN);
$t->package_not_latest_ok('Baz', $dist_name, $FOREIGN);

#------------------------------------------------------------------------------
# After removing our local version, the foreign version should become latest...

$pinto->new_batch();
$pinto->add_action('Remove', path => $dist_name, author => $LOCAL1 );
$pinto->run_actions();

$t->package_not_loaded_ok('Bar', $dist_name, $LOCAL1);
$t->package_not_loaded_ok('Baz', $dist_name, $LOCAL1);
$t->dist_not_exists_ok($dist_name, $LOCAL1);

$t->package_is_latest_ok('Bar', $dist_name, $FOREIGN);
$t->package_is_latest_ok('Baz', $dist_name, $FOREIGN);
