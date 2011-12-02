#!perl

use strict;
use warnings;

use Test::More (tests => 23);

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------
# For this test, we use both the 'a' and 'b' repositories...

my $fakes    = dir( $Bin, qw(data fakepan repos) );
my $source_a = URI->new("file://$fakes/a");
my $source_b = URI->new("file://$fakes/b");
my $sources  = join ' ', $source_a, $source_b;
my $LOCAL    = 'LOCAL';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new( creator_args => {sources => $sources} );
my $pinto = $t->pinto();

#------------------------------------------------------------------------------
# Import recursively w/ multiple repositories

$pinto->new_batch();
$pinto->add_action('Import', package_name => 'Salad');
$t->result_ok( $pinto->run_actions() );

# Salad requires Dressing-0 and Lettuce-1.0
$t->dist_exists_ok('Salad-1.0.0.tar.gz', $LOCAL);
$t->package_loaded_ok('Salad', 'Salad-1.0.0.tar.gz', $LOCAL, 'v1.0.0');
$t->package_is_latest_ok('Salad', 'Salad-1.0.0.tar.gz', $LOCAL);

# Only repository 'b' has Letuce > 1.0
$t->dist_exists_ok('Lettuce-2.0.tar.gz', $LOCAL);
$t->package_loaded_ok('Lettuce', 'Lettuce-2.0.tar.gz', $LOCAL, '2.0');
$t->package_is_latest_ok('Lettuce', 'Lettuce-2.0.tar.gz', $LOCAL);

# Dressing-v1.9.0 requires Oil-3.0 and Vinegar-v5.1.2
$t->dist_exists_ok('Dressing-v1.9.0.tar.gz', $LOCAL);
$t->package_loaded_ok('Dressing', 'Dressing-v1.9.0.tar.gz', $LOCAL, 'v1.9.0');
$t->package_is_latest_ok('Dressing', 'Dressing-v1.9.0.tar.gz', $LOCAL);

# Repository 'a' has Oil-3.0, but 'b' has Oil-4.0
$t->dist_exists_ok('Oil-4.0.tar.gz', $LOCAL);
$t->package_loaded_ok('Oil', 'Oil-4.0.tar.gz', $LOCAL, '4.0');
$t->package_is_latest_ok('Oil', 'Oil-4.0.tar.gz', $LOCAL);
$t->dist_not_exists_ok('Oil-3.0.tar.gz', $LOCAL);
$t->package_not_loaded_ok('Oil', 'Oil-3.0.tar.gz', $LOCAL, '3.0');

# Only repository 'b' has any Vinegar at all
$t->dist_exists_ok('Vinegar-v5.1.3.tar.gz', $LOCAL);
$t->package_loaded_ok('Vinegar', 'Vinegar-v5.1.3.tar.gz', $LOCAL, 'v5.1.3');
$t->package_is_latest_ok('Vinegar', 'Vinegar-v5.1.3.tar.gz', $LOCAL);

print ${ $t->buffer() };
