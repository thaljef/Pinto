#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

my $rev = shift;

#-----------------------------------------------------------------------------

my $t = Pinto::Tester->new;
my $archive1 = make_dist_archive('Dist-1 = PkgA~1,PkgB~1,PkgC~1');
sleep 1;
my $archive2 = make_dist_archive('Dist-2 = PkgA~2,PkgB~1,PkgD~1');

$t->run_ok(Add     => {archives => $archive1});            # Rev 1
$t->run_ok(Pin     => {targets  => 'PkgA'});               # Rev 2
$t->run_ok(Revert  => {stack    => 'master'});               # Rev 3
$t->run_ok(Add     => {archives => $archive2});            # Rev 4
$t->run_ok(Pop     => {targets  => 'JEFF/Dist-1.tar.gz'}); # Rev 5
$t->run_ok(Pin     => {targets  => 'PkgD'});               # Rev 6
$t->run_ok(Unpin   => {targets  => 'PkgA'});               # Rev 7
$t->run_ok(Reindex => {targets  => 'JEFF/Dist-1.tar.gz'}); # Rev 6

print ">>>>>>>\n";
use Pinto::StackSnapshot;
my $stack = $t->pinto->repo->get_stack;
my $snapshot = Pinto::StackSnapshot->new(stack => $stack, revision => $rev);
print "$snapshot\n";

#-----------------------------------------------------------------------------

done_testing;