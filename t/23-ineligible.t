#!perl

use strict;
use warnings;

use Test::More (tests => 8);

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $dists_dir = dir( $Bin, qw(data ineligible dists) );
my $LOCAL = 'LOCAL';
my $archive;

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();

#------------------------------------------------------------------------------

$pinto->new_batch();
$archive = $dists_dir->file('Invalid-Dist-Version-1.0.BOGUS.tar.gz');
$pinto->add_action('Add', archive => $archive);
$t->result_ok( $pinto->run_actions() );
like $t->bufferstr(), qr/ineligible for indexing: Illegal version/;
$t->reset_buffer();

#------------------------------------------------------------------------------
# These dists both have package Bar-1.0, but they are in dists with different
# names.  Therefore, we cannot compare them so the later one is ineligible.

my $part1 = 'Unsortable-Part1-1.0.tar.gz';
my $part2 = 'Unsortable-Part2-2.0.tar.gz';

$pinto->new_batch();
$pinto->add_action('Add', author => $LOCAL, archive => $dists_dir->file($part1));
$pinto->add_action('Add', author => $LOCAL, archive => $dists_dir->file($part2));
$t->result_ok( $pinto->run_actions() );

like $t->bufferstr(), qr/ineligible for indexing: Cannot compare distributions/;

$t->dist_exists_ok($part1, $LOCAL);
$t->package_is_latest_ok('Baz', $part1, $LOCAL);

$t->dist_exists_ok($part2, $LOCAL);
$t->package_not_latest_ok('Baz', $part2, $LOCAL);


