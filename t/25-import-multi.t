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

#------------------------------------------------------------------------------
# Pull recursively w/ multiple repositories

$t->run_ok('Pull', {targets => 'Salad'});
$t->package_ok( "$them/Salad-1.0.0/Salad-1.0.0");

# Salad requires Dressing-0
$t->package_ok( "$them/Dressing-v1.9.0/Dressing-v1.9.0" );

# And salad requires Lettuce-1.0
# Repository 'b' has Lettuce 0.8, but that is too low
# Only repository 'c' has Letuce >= 1.0
$t->package_ok( "$them/Lettuce-2.0/Lettuce-2.0" );

# Dressing-v1.9.0 requires Oil-3.0
# Repository 'b' has Oil-3.0, but repository 'c' has Oil-4.0.
# We should only have the newer one of the two.
$t->package_ok( "$them/Oil-4.0/Oil-4.0" );

# Dressing-v1.9.0 requires Vinegar-v5.1.2
# Only repository 'b' has any Vinegar at all
$t->package_ok( "$them/Vinegar-v5.1.3/Vinegar-v5.1.3" );

#------------------------------------------------------------------------------
# Now, let's suppose we decide that we must use a patched version of Oil-3.0
# from the 'b' repository instead of the required Oil-4.0 from the 'c' repo.

my $auth_dir = dir( $Bin, qw(data fakepan repos b authors id L LO LOCAL) );
my $archive  = $auth_dir->file( 'Oil-3.0.tar.gz' );
my $us       = 'US'; # Local author

$t->run_ok('Add', {archives => $archive, author => $us});

# Our Oil-3.0 should be latest
$t->package_ok( "$us/Oil-3.0/Oil-3.0" );

#------------------------------------------------------------------------------

done_testing;
