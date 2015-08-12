#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::File;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------
# Setup a repository...

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------
subtest 'exclusive locking' => sub {

    note 'Testing exclusive locking';

    my $pid = fork;
    die "fork failed: $!" unless defined $pid;

    if ($pid) {

        # parent
        sleep 3;    # Let the child start
        print "Starting parent: $$\n";

        my $lock_file = $t->root->file('.lock');
        file_exists_ok($lock_file);

        local $Pinto::Locker::LOCKFILE_TIMEOUT = 5;
        $t->run_throws_ok( 'Nop', {}, qr/currently in use/, 'Operation denied when exclusive lock is in place' );

        my $kid = wait;    # Let the child finish
        is( $kid, $pid, "reaped correct child" );
        is( $?,   0,    "child finished succesfully" );
        file_not_exists_ok($lock_file);

        $t->run_ok( 'Nop', {}, 'Operation allowed after exclusive lock is removed' );

    }
    else {
        # child
        print "Starting child: $$\n";

        require Pinto::Action::Pull;

        no warnings qw(redefine once);

        # Override the execute method to just sit and idle
        local *Pinto::Action::Pull::execute = sub { sleep 12; return $_[0]->result };

        my $result = $t->pinto->run( 'Pull', targets => 'whatever' );

        exit $result->exit_status;
    }

};

#------------------------------------------------------------------------------
subtest 'shared locking' => sub {

    note 'Testing shared locking';

    my $pid = fork;
    die "fork failed: $!" unless defined $pid;

    if ($pid) {

        # parent
        sleep 3;    # Let the child start
        print "Starting parent: $$\n";

        my $lock_file = $t->root->file('.lock');
        file_exists_ok($lock_file);

        local $Pinto::Locker::LOCKFILE_TIMEOUT = 5;
        $t->run_ok( 'List', {}, 'Non-excusive operation allowed with shared lock' );

        $t->run_throws_ok(
            'Pull',
            { targets => 'whatever' },
            qr/currently in use/,
            'Exclusive operation denied when shared lock is in place'
        );

        my $kid = wait;    # Let the child finish
        is( $kid, $pid, "reaped correct child" );
        is( $?,   0,    "child finished succesfully" );
        file_not_exists_ok($lock_file);

    }
    else {
        # child
        print "Starting child: $$\n";

        require Pinto::Action::List;

        no warnings qw(redefine once);

        # Override the execute method to just sit and idle
        local *Pinto::Action::List::execute = sub { sleep 15; return $_[0]->result };

        my $result = $t->pinto->run('List');

        exit $result->exit_status;
    }

};

#------------------------------------------------------------------------------
subtest 'Test stale lock file' => sub {

    # create dummy lock file not connected to us
    my $lockfile = $t->root->file('.lock');
    $lockfile->touch;
    $t->path_exists_ok( $lockfile, 'dummy lockfile exists' );

    # confirm error thrown if unable to obtain lock
    local $Pinto::Locker::LOCKFILE_TIMEOUT       = 4;  # wait 4 seconds to acquire lock
    local $Pinto::Locker::STALE_LOCKFILE_TIMEOUT = 0;  # don't expire stale lock
    throws_ok { $t->pinto->repo->lock( 'EX' ) } 'Pinto::Exception', 'repo locked elsewhere';

    # confirm we can steal lock
    local $Pinto::Locker::STALE_LOCKFILE_TIMEOUT = 2;  # steal lock after 2 seconds
    sleep( $Pinto::Locker::STALE_LOCKFILE_TIMEOUT + 1 );
    isa_ok( $t->pinto->repo->lock( 'EX' ), 'Pinto::Locker', 'steal the repo lock' );
    ok( $t->pinto->repo->unlock, 'unlock repo');
    $t->path_not_exists_ok( $lockfile, 'confirm lockfile removed' );

};

#------------------------------------------------------------------------------
done_testing;
