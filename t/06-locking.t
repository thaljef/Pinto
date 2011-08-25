#!perl

use strict;
use warnings;

use Test::More (tests => 2);

use File::Temp;
use Path::Class;

use Pinto;

#------------------------------------------------------------------------------

my $buffer = '';
my $repos  = File::Temp::tempdir(CLEANUP => 1);
my $pinto  = Pinto->new(repos => $repos, out => \$buffer, verbose => 2);
$pinto->new_action_batch();

#------------------------------------------------------------------------------
# Finally, we can do a test now..


my $pid = fork();
die "fork failed: $!" unless defined $pid;

if ($pid) {
    # parent
    sleep 10; # Let the child get started
    print "Starting: $$\n";
    $pinto->add_action('Nop');
    $pinto->run_actions();
    like($buffer, qr/Unable to lock/, 'Repository is locked by sleeper');

    wait; # Let the child finish
    $pinto->add_action('Nop');
    $pinto->run_actions();
    like($buffer, qr/got the lock/, 'Got lock after the sleeper died');
}
else {
    # child
    print "Starting: $$\n";
    $pinto->add_action('Nop', sleep => 70);
    $pinto->run_actions();
    exit 0;
}




