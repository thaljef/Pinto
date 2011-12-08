#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;

#------------------------------------------------------------------------------
# Setup a repository...

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();
$pinto->new_batch();

#------------------------------------------------------------------------------

is($pinto->locker->is_locked(), '', 'Repository is not locked initially');

#------------------------------------------------------------------------------
# Now fork and have two processes run an action at the same time...


my $pid = fork();
die "fork failed: $!" unless defined $pid;

if ($pid) {
    # parent
    sleep 10; # Let the child get started
    print "Starting: $$\n";
    $pinto->add_action('Nop');

    throws_ok { $pinto->run_actions() } qr/Unable to lock/,
      'Refused access to locked repository';

    my $kid = wait; # Let the child finish
    is($kid, $pid, "reaped correct child");
    is($?, 0, "child finished succesfully");

    $pinto->add_action('Nop');
    lives_ok { $pinto->run_actions() }
      'Got access after the sleeper died';
}
else {
    # child
    print "Starting: $$\n";
    $pinto->add_action('Nop', sleep => 70);
    $pinto->run_actions();
    exit 0;
}

#------------------------------------------------------------------------------

done_testing();
