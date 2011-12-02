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
# Simple import...

$pinto->new_batch();
$pinto->add_action('Import', norecurse => 1, package_name => 'Salad');

$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$them/Salad-1.0.0.tar.gz/Salad-1.0.0", 1);

#------------------------------------------------------------------------------
# Add a local copy of a dependency

my $dist = 'Oil-3.0.tar.gz';
my $archive = $auth_dir->file($dist);

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $us);

$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$us/$dist/Oil-3.0", 1);

#------------------------------------------------------------------------------
# Import recursive...

$pinto->new_batch();
$pinto->add_action('Import', package_name => 'Salad');

$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$them/Salad-1.0.0.tar.gz/Salad-1.0.0", 1);

# Salad requires Dressing-0 and Lettuce-1.0
$t->package_loaded_ok( "$them/Dressing-v1.9.0.tar.gz/Dressing-v1.9.0", 1);

# The 'a' repository only has Lettuce-0.08, so we shouldn't import it
$t->package_not_loaded_ok( "$them/Lettuce-0.8.tar.gz/Lettuce-0.08" );
$t->log_like( qr{Cannot find Lettuce-1.0 anywhere} );

# Dressing-v1.9.0 requires Oil-3.0 and Vinegar-v5.1.2.
# But we already have our own local copy of Oil (from above)
$t->package_loaded_ok( "$us/Oil-3.0.tar.gz/Oil-3.0", 1);

# So we should not have imported their Oil
$t->package_not_loaded_ok( "$them/Oil-3.0.tar.gz/Oil-3.0" );

# Lastly, the 'a' repository does not have Vinegar at all
$t->package_not_loaded_ok( "$them/Vinegar-v5.1.2.tar.gz/Vinegar-v5.1.2" );

#------------------------------------------------------------------------------

done_testing();
