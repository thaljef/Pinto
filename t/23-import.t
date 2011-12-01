#!perl

use strict;
use warnings;

use Test::More (tests => 18);

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------
# Fo this test, we're only using the 'a' repository...

my $fakes  = dir( $Bin, qw(data fakepan repos a) );
my $source = URI->new("file://$fakes");
my $LOCAL  = 'LOCAL';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new( creator_args => {sources => "$source"} );
my $pinto = $t->pinto();

#------------------------------------------------------------------------------
# Simple import...

$pinto->new_batch();
$pinto->add_action('Import', norecurse => 1, package_name => 'Salad');
$t->result_ok( $pinto->run_actions() );

$t->dist_exists_ok('Salad-1.0.0.tar.gz', $LOCAL);
$t->package_loaded_ok('Salad', 'Salad-1.0.0.tar.gz', $LOCAL, 'v1.0.0');

#------------------------------------------------------------------------------
# Import recursive...

$pinto->new_batch();
$pinto->add_action('Import', package_name => 'Salad');
$t->result_ok( $pinto->run_actions() );

# Salad requires Dressing-0 and Lettuce-1.0
$t->dist_exists_ok('Salad-1.0.0.tar.gz', $LOCAL);
$t->package_loaded_ok('Salad', 'Salad-1.0.0.tar.gz', $LOCAL, 'v1.0.0');

# Dressing-v1.9.0 requires Oil-3.0 and Vinegar-v5.1.2
$t->dist_exists_ok('Dressing-v1.9.0.tar.gz', $LOCAL);
$t->package_loaded_ok('Dressing', 'Dressing-v1.9.0.tar.gz', $LOCAL, 'v1.9.0');

$t->dist_exists_ok('Oil-3.0.tar.gz', $LOCAL);
$t->package_loaded_ok('Oil', 'Oil-3.0.tar.gz', $LOCAL, '3.0');

# The 'a' repository only has Lettuce-0.08
$t->dist_not_exists_ok( 'Lettuce-0.8.tar.gz', $LOCAL );
$t->package_not_loaded_ok('Lettuce', 'Lettuce-0.8.tar.gz', $LOCAL );

# The 'a' repository does not have Vinegar at all
$t->dist_not_exists_ok( 'Vinegar-v5.1.3.tar.gz', $LOCAL );
$t->package_not_loaded_ok('Vinegar', 'Vinegar-v5.1.3.tar.gz', $LOCAL );

print ${ $t->buffer() };
