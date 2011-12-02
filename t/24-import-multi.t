#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------
# For this test, we use both the 'b' and 'c' repositories...

my $fakes    = dir( $Bin, qw(data fakepan repos) );
my $source_b = URI->new("file://$fakes/b");
my $source_c = URI->new("file://$fakes/c");
my $sources  = join ' ', $source_b, $source_c;
my $them     = 'LOCAL';  # Foreign author, used by CPAN::Faker

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new( creator_args => {sources => $sources} );
my $pinto = $t->pinto();

#------------------------------------------------------------------------------
# Import recursively w/ multiple repositories

$pinto->new_batch();
$pinto->add_action('Import', package_name => 'Salad');

$t->result_ok( $pinto->run_actions() );
$t->package_loaded_ok( "$them/Salad-1.0.0.tar.gz/Salad-1.0.0", 1 );

# Salad requires Dressing-0
$t->package_loaded_ok( "$them/Dressing-v1.9.0.tar.gz/Dressing-v1.9.0", 1);

# And salad requires Lettuce-1.0

# Repository 'b' has Lettuce 0.8, but that is too low
$t->package_not_loaded_ok( "$them/Lettuce-0.8.tar.gz/Lettuce-0.8", 1 );

# Only repository 'c' has Letuce >= 1.0
$t->package_loaded_ok( "$them/Lettuce-2.0.tar.gz/Lettuce-2.0", 1 );

# Dressing-v1.9.0 requires Oil-3.0
# Repository 'b' has Oil-3.0, but repository 'c' has Oil-4.0.
# We should only have the newer one of the two.
$t->package_not_loaded_ok( "$them/Oil-3.0.tar.gz/Oil-3.0" );
$t->package_loaded_ok( "$them/Oil-4.0.tar.gz/Oil-4.0", 1 );

# Dressing-v1.9.0 requires Vinegar-v5.1.2
# Only repository 'b' has any Vinegar at all
$t->package_loaded_ok( "$them/Vinegar-v5.1.3.tar.gz/Vinegar-v5.1.3", 1 );

#------------------------------------------------------------------------------
# Now, let's suppose we decide that we must use a patched version of Oil-3.0
# from the 'b' repository instead of the required Oil-4.0 from the 'c' repo.

my $auth_dir = dir( $Bin, qw(data fakepan repos b authors id L LO LOCAL) );
my $archive  = $auth_dir->file( 'Oil-3.0.tar.gz' );
my $us       = 'US'; # Local author

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $us);

$t->result_ok( $pinto->run_actions() );

# Our Oil-3.0 should be latest
$t->package_loaded_ok( "$us/Oil-3.0.tar.gz/Oil-3.0", 1 );

# And their Oil-4.0 should not be latest
$t->package_loaded_ok( "$them/Oil-4.0.tar.gz/Oil-4.0", 0 );

#------------------------------------------------------------------------------
done_testing();
