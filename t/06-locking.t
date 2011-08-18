#!perl

use strict;
use warnings;

use Test::More (tests => 2);
use Test::Exception;

use File::Temp;
use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Pinto::Store;
use Pinto::ActionBatch;
use Pinto::IndexManager;

use Pinto::TestLogger;
use Pinto::TestConfig;
use Pinto::TestAction;

#------------------------------------------------------------------------------
# Ugh, this is a lot of setup.

my $repos  = File::Temp::tempdir(CLEANUP => 1);
my $config = Pinto::TestConfig->new(local => $repos);
my $logger = Pinto::TestLogger->new(config => $config, out => \my $buffer);
my %config_and_logger = (config => $config, logger => $logger);

my $idxmgr = Pinto::IndexManager->new(%config_and_logger);
my $store  = Pinto::Store->new(%config_and_logger);
my %store_and_idxmgr = (store => $store, idxmgr => $idxmgr);

my %all_of_it = (%config_and_logger, %store_and_idxmgr);
my $batch   = Pinto::ActionBatch->new(%all_of_it);

my $sleeper     = Pinto::TestAction->new( %all_of_it, callback => sub {sleep 70} );
my $competitor  = Pinto::TestAction->new( %all_of_it );

#------------------------------------------------------------------------------
# Finally, we can do a test now..


my $pid = fork();
die "fork failed: $!" unless defined $pid;

if ($pid) {
    # parent
    sleep 10; # Let the child get started
    print "Starting: $$\n";
    throws_ok{ $batch->enqueue($competitor)->run() }
      qr/Unable to lock/, 'Repository is locked by sleeper';

    wait; # Let the child finish
    lives_ok { $batch->enqueue($competitor)->run() }
      'Got lock after the sleeper died';
}
else {
    # child
    print "Starting: $$\n";
    $batch->enqueue($sleeper)->run();
    exit 0;
}




