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

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new( creator_args => {sources => $source} );
my $pinto = $t->pinto();

#------------------------------------------------------------------------------
# Populate the reposiory with some stuff...

$pinto->new_batch();
$pinto->add_action('Mirror');
$t->result_ok( $pinto->run_actions() );

#------------------------------------------------------------------------------
# Now delete the index file

my $index = $t->pinto->config->packages_details_file();
ok( -e $index, "Index file $index exists");

$index->remove();
ok( ! -e $index, "Index file $index has been removed");


#------------------------------------------------------------------------------
# Now rebuild the index file

$pinto->new_batch();
$pinto->add_action('Rebuild', recompute => 1);
$t->result_ok( $pinto->run_actions() );

ok( -e $index, "Index file $index has been restored");

#------------------------------------------------------------------------------
# TODO: Forcibly change the version numbers on some packages, so that
# the 'recompute' option actually changes the content of the index.
# Then verify that the index changed as expected.
#------------------------------------------------------------------------------

done_testing();
