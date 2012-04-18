#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $auth    = 'ME';
my $pkg1    = 'Foo-0.01';
my $pkg2    = 'Bar-0.01';
my $dist    = 'Foo-Bar-0.01';
my $archive = make_dist_archive("$dist=$pkg1,$pkg2");

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();

#------------------------------------------------------------------------------
# Adding a local dist...

$pinto->new_batch();
$pinto->add_action( 'Add', archive => $archive, author => $auth );
$t->result_ok( $pinto->run_actions() );
$t->package_ok("$auth/$dist/$pkg1/default");
$t->package_ok("$auth/$dist/$pkg2/default");

#-----------------------------------------------------------------------------
# Adding to alternative stack...

$t = Pinto::Tester->new();
$pinto = $t->pinto();

$pinto->new_batch();
$pinto->add_action('Stack::Create', stack => 'dev');
$pinto->add_action('Add', archive => $archive, author => $auth, stack => 'dev');
$t->result_ok( $pinto->run_actions() );

# Should be on both the default and dev stacks
$t->package_ok( "$auth/$dist/$pkg1/default" );
$t->package_ok( "$auth/$dist/$pkg2/default" );
$t->package_ok( "$auth/$dist/$pkg1/dev" );
$t->package_ok( "$auth/$dist/$pkg2/dev" );

#-----------------------------------------------------------------------------
# Exceptions...

$pinto->new_batch;
$pinto->add_action('Add', archive => $archive, author => $auth);
throws_ok {$pinto->run_actions} qr/already exists/, 'Cannot add same dist twice';

$pinto->new_batch();
$pinto->add_action('Add', archive => 'none_such', author => $auth);
throws_ok {$pinto->run_actions} qr/does not exist/, 'Cannot add nonexistant archive';

#-----------------------------------------------------------------------------

done_testing;
