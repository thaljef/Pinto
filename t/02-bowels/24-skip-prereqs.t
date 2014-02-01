#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t1 = Pinto::Tester->new; # Empty upstream repository
my $t2 = Pinto::Tester->new(init_args => {sources => $t1->stack_url});
my $archive = make_dist_archive('AUTHOR/DistA-1 = PkgA~1 & PkgB~1; PkgC~1');
my $expected_registration = 'AUTHOR/DistA-1/PkgA~1';

#------------------------------------------------------------------------------

subtest 'Skip all missing prereqs when adding' => sub {

    $t2->run_ok( Add => { archives => $archive, skip_all_missing_prerequisites => 1 } );
    $t2->stderr_like(qr/Cannot find PkgB~1 anywhere.  Skipping it/);
    $t2->registration_ok($expected_registration);
};

#------------------------------------------------------------------------------

subtest 'Skip all missing prereqs when pulling' => sub {

	my $stack = 'foo';

	$t2->run_ok( New => {stack => $stack});
	$t2->stack_is_empty_ok($stack);

    $t2->run_ok( Pull => {targets => 'PkgA', stack => $stack, skip_all_missing_prerequisites => 1 });
  	$t2->stderr_like(qr/Cannot find PkgB~1 anywhere.  Skipping it/);
    $t2->registration_ok("$expected_registration/$stack");
};

#------------------------------------------------------------------------------

subtest 'Skip all named missing prereqs when pulling' => sub {

    my $stack = 'bar';

    $t2->run_ok( New => {stack => $stack});
	$t2->stack_is_empty_ok($stack);

    $t2->run_ok( Pull => {targets => 'PkgA', stack => $stack, skip_missing_prerequisite => [qw(PkgB PkgC)] });
  	$t2->stderr_like(qr/Cannot find PkgB~1 anywhere.  Skipping it/);
    $t2->registration_ok("AUTHOR/DistA-1/PkgA~1/bar/$stack");
};

#------------------------------------------------------------------------------

subtest 'Skip just some named missing prereqs when pulling' => sub {

    my $stack = 'baz';

    $t2->run_ok( New => {stack => $stack});
	$t2->stack_is_empty_ok($stack);

    $t2->run_throws_ok( Pull => {targets => 'PkgA', stack => $stack, skip_missing_prerequisite => [qw(PkgC)] },
    	qr/Cannot find PkgB~1 anywhere/ );
};

#------------------------------------------------------------------------------
done_testing;
