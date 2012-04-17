#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------
# Fo this test, we're only using the 'b' repository...

my $fakes    = dir( $Bin, qw(data fakepan repos b) );
my $source   = URI->new("file://$fakes");
my $auth_dir = $fakes->subdir( qw( authors id L LO LOCAL) );

my $us       = 'US';    # The local author
my $them     = 'LOCAL'; # Foreign author (used by CPAN::Faker)

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new( creator_args => {sources => "$source"} );
my $pinto = $t->pinto();

$t->repository_empty_ok();

#------------------------------------------------------------------------------
# Import by distribution spec (rather than by package spec)

$pinto->new_batch();
$pinto->add_action('Import', target => "$them/Salad-1.0.0.tar.gz");

$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$them/Salad-1.0.0.tar.gz/Salad-1.0.0", 1);

#------------------------------------------------------------------------------

done_testing;
