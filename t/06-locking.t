#!perl

use strict;
use warnings;

use Test::More (tests => 4);
use Test::Exception;

use File::Temp;
use Path::Class;

use Pinto;

#------------------------------------------------------------------------------

my $buffer = '';
my $root_dir  = File::Temp::tempdir(CLEANUP => 1);
my $pinto  = Pinto->new(root_dir => $root_dir, out => \$buffer, verbose => 2);
$pinto->new_batch();

#------------------------------------------------------------------------------
# Finally, we can do a test now..


my $pid = fork();
die "fork failed: $!" unless defined $pid;

if ($pid) {
    # parent
    sleep 10; # Let the child get started
    print "Starting: $$\n";
    $pinto->add_action('Nop');

    throws_ok { $pinto->run_actions() } qr/Unable to lock/,
      'Repository is locked by sleeper';

    my $kid = wait; # Let the child finish
    is($kid, $pid, "reaped correct child");
    is($?, 0, "child finished succesfully");

    $pinto->add_action('Nop');
    lives_ok { $pinto->run_actions() }
      'Got lock after the sleeper died';
}
else {
    # child
    print "Starting: $$\n";
    $pinto->add_action('Nop', sleep => 70);
    $pinto->run_actions();
    exit 0;
}




