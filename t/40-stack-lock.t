#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

{
	my $t = Pinto::Tester->new;
	my $archive = make_dist_archive('Foo-1 = Foo~1');
	my $stack = $t->pinto->repo->get_stack;

	$t->run_ok(Lock => {});
	is $stack->refresh->is_locked, 1, 'Stack is locked';

	$t->run_throws_ok(Add => {archives => $archive},
			          qr/is locked/, 'Cannot modify locked stack');

	$t->run_ok(Unlock => {});
	is $stack->refresh->is_locked, 0, 'Stack is unlocked';

	$t->run_ok(Add => {archives => $archive});
}

#------------------------------------------------------------------------------

done_testing;

