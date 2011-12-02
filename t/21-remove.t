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
my $dist      = 'FooOnly-0.01.tar.gz';
my $pkg       = 'Foo-0.01';
my $archive   = $auth_dir->file($dist);

# A couple local authors...
my $auth1 = 'AUTHOR1';
my $auth2 = 'AUTHOR2';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();

$t->repository_empty_ok();

#------------------------------------------------------------------------------
# Adding a local dist...

$pinto->new_batch();
$pinto->add_action( 'Add', archive => $archive, author => $auth1 );

$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$auth1/$dist/$pkg", 1 );

#------------------------------------------------------------------------------
# Removing the local dist...

$pinto->new_batch();
$pinto->add_action( 'Remove', path => $dist, author => $auth2 );

$t->result_not_ok( $pinto->run_actions() );
$t->log_like( qr{$auth2/$dist does not exist},
              'Cannot remove dist owned by another author' );

$pinto->new_batch();
$pinto->add_action('Remove', path => $dist, author => $auth1 );

$t->result_ok( $pinto->run_actions() );
$t->package_not_loaded_ok( "$auth1/$dist/$pkg" );
$t->path_not_exists_ok( [ qw( authors id A AU AUTHOR ) ] );
$t->repository_empty_ok();

#------------------------------------------------------------------------------
# Add the dist again...

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $auth1);
$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$auth1/$dist/$pkg", 1 );

#------------------------------------------------------------------------------
# Now remove via full path name...

$pinto->new_batch();
$pinto->add_action('Remove', path => "A/AU/AUTHOR1/$dist");

$t->result_ok( $pinto->run_actions() );
$t->package_not_loaded_ok( "$auth1/$dist/$pkg" );
$t->path_not_exists_ok( [ qw( authors id A AU AUTHOR ) ] );
$t->repository_empty_ok();

done_testing();
