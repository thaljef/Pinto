#!perl

use strict;
use warnings;

use Test::More;
use Test::File;

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
    sleep 3; # Let the child start
    print "Starting parent: $$\n";

    my $lock_file = $t->root->file('.lock.NFSLock');
    file_exists_ok($lock_file);

    local $Pinto::Locker::LOCKFILE_TIMEOUT = 5;
    $t->run_throws_ok('Nop', {}, qr/Unable to lock/,
      'Parent refused access to locked repository');

    my $kid = wait; # Let the child finish
    is($kid, $pid, "reaped correct child");
    is($?, 0, "child finished succesfully");

    $t->run_ok('Nop', {}, 'Got access after the child died');
    file_not_exists_ok($lock_file);
}
else {
    # child
    print "Starting child: $$\n";
    my $result = $t->pinto->run('Nop', sleep => 12);
    exit $result->exit_status;
}

#------------------------------------------------------------------------------

done_testing;
