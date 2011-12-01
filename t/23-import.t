#!perl

use strict;
use warnings;

use Test::More (tests => 10);

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $fakes     = dir( $Bin, qw(data fakepan repos a) );
my $source    = URI->new("file://$fakes");
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );
my $dist_name = 'FooOnly-0.01.tar.gz';
my $archive   = $auth_dir->file($dist_name);
my $LOCAL     = 'LOCAL';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new( creator_args => {sources => "$source"} );
my $pinto = $t->pinto();

# Make sure we have clean slate
$t->package_not_loaded_ok('Foo', $dist_name, $LOCAL);
$t->dist_not_exists_ok($dist_name, $LOCAL);

#------------------------------------------------------------------------------
# Import from a foreign repository...

$pinto->new_batch();
$pinto->add_action('Import', norecurse => 1, package_name => 'Foo');
$t->result_ok( $pinto->run_actions() );

$t->dist_exists_ok('FooAndBar-0.02.tar.gz', $LOCAL);
$t->package_loaded_ok( 'Foo', 'FooAndBar-0.02.tar.gz', $LOCAL, '0.02' );
$t->package_loaded_ok( 'Bar', 'FooAndBar-0.02.tar.gz', $LOCAL, '0.02' );

$t->package_is_latest_ok( 'Foo', 'FooAndBar-0.02.tar.gz', $LOCAL );
$t->package_is_latest_ok( 'Bar', 'FooAndBar-0.02.tar.gz', $LOCAL );
