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

$t->repository_empty_ok();

#------------------------------------------------------------------------------
# Fill the repitory with some stuff

$pinto->new_batch();
$pinto->add_action('Mirror');
$t->result_ok( $pinto->run_actions() );


#------------------------------------------------------------------------------
# Then get rid of it

$pinto->new_batch();
$pinto->add_action('Purge');
$t->result_ok( $pinto->run_actions() );

$t->repository_empty_ok();

#------------------------------------------------------------------------------

done_testing();
