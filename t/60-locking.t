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

{

  note 'Testing exclusive locking';

  my $pid = fork;
  die "fork failed: $!" unless defined $pid;

  if ($pid) {
      # parent
      sleep 3; # Let the child start
      print "Starting parent: $$\n";

      my $lock_file = $t->root->file('.lock');
      file_exists_ok($lock_file);

      local $Pinto::Locker::LOCKFILE_TIMEOUT = 5;
      $t->run_throws_ok('Nop', {}, qr/Unable to lock/,
          'Operation deined when exclusive lock is in place');

      my $kid = wait; # Let the child finish
      is($kid, $pid, "reaped correct child");
      is($?, 0, "child finished succesfully");
      file_not_exists_ok($lock_file);

      $t->run_ok('Nop', {}, 'Operation allowed after exclusive lock is removed');

  }
  else {
      # child
      print "Starting child: $$\n";

      no warnings qw(redefine once);
      require Pinto::Action::Pull;
      # Override the execute method to just sit and idle
      local *Pinto::Action::Pull::execute = sub { sleep 12; return $_[0]->result };

      my $result = $t->pinto->run('Pull', targets => 'whatever');
      exit $result->exit_status;
  }
}

#------------------------------------------------------------------------------

{

  note 'Testing shared locking';

  my $pid = fork;
  die "fork failed: $!" unless defined $pid;

  if ($pid) {
      # parent
      sleep 3; # Let the child start
      print "Starting parent: $$\n";

      my $lock_file = $t->root->file('.lock');
      file_exists_ok($lock_file);

      local $Pinto::Locker::LOCKFILE_TIMEOUT = 5;
      $t->run_ok('List', {}, 'Non-excusive operation allowed with shared lock');

      $t->run_throws_ok('Pull', {targets => 'whatever'}, qr/Unable to lock/,
        'Excuisve operation denied when shared lock is in place');

      my $kid = wait; # Let the child finish
      is($kid, $pid, "reaped correct child");
      is($?, 0, "child finished succesfully");
      file_not_exists_ok($lock_file);

  }
  else {
      # child
      print "Starting child: $$\n";

      no warnings qw(redefine once);
      require Pinto::Action::List;
      # Override the execute method to just sit and idle
      local *Pinto::Action::List::execute = sub { sleep 15; return $_[0]->result };

      my $result = $t->pinto->run('List');
      exit $result->exit_status;
  }

}

#------------------------------------------------------------------------------
done_testing;
