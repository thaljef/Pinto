#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;

#------------------------------------------------------------------------------
# Setup a repository...

my $t = Pinto::Tester->new;
$t->pinto; # Just to kick lazy initializers

#------------------------------------------------------------------------------
# Now fork and have two processes run an action at the same time...

my $pid = fork;
die "fork failed: $!" unless defined $pid;

if ($pid) {
    # parent
    sleep 10; # Let the child start
    print "Starting parent: $$\n";

    $t->run_throws_ok('Nop', {}, qr/Unable to lock/,
      'Parent refused access to locked repository');

    my $kid = wait; # Let the child finish
    is($kid, $pid, "reaped correct child");
    is($?, 0, "child finished succesfully");

    $t->run_ok('Nop', {}, 'Got access after the child died');
}
else {
    # child
    print "Starting child: $$\n";
    warn "Will be sleeping for 70 seconds, don't be alarmed...\n";
    my $r = $t->run_ok('Nop', {sleep => 70}, 'Child locks the repository');
    exit 0;
}

#------------------------------------------------------------------------------

done_testing;
