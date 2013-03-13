#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

{
	my $t = Pinto::Tester->new->populate('AUTHOR/Foo-1=Foo~1');
	my $archive = make_dist_archive('Foo-2=Foo~2');

	# First, assert stack is initially unlocked
	$t->stack_is_not_locked_ok('master');

	# Now lock the stack
	$t->run_ok(Lock => {});
	$t->stack_is_locked_ok('master');

	# Try and modify the stack
	$t->run_throws_ok(Add => {archives => $archive},
			          qr/is locked/, 'Cannot Add to locked stack');

	$t->run_throws_ok(Pin => {targets => 'Foo'},
			          qr/is locked/, 'Cannot Pin on locked stack');

	$t->run_throws_ok(Unpin => {targets => 'Foo'},
			          qr/is locked/, 'Cannot Unpin on locked stack');

	$t->run_throws_ok(Unregister => {targets => 'AUTHOR/Foo-1.tar.gz'},
			          qr/is locked/, 'Cannot Unregister from locked stack');

	$t->run_throws_ok(Register => {targets => 'AUTHOR/Foo-1.tar.gz'},
			          qr/is locked/, 'Cannot Register on locked stack');


	# Now unlock the stack
	$t->run_ok(Unlock => {});
	$t->stack_is_not_locked_ok('master');

	# Try modifying again
	$t->run_ok(Add        => {archives => $archive});
	$t->run_ok(Pin        => {targets  => 'Foo'});
	$t->run_ok(Unpin      => {targets  => 'Foo'});
	$t->run_ok(Unregister => {targets  => 'AUTHOR/Foo-2.tar.gz'});
	$t->run_ok(Register   => {targets  => 'AUTHOR/Foo-2.tar.gz'});
}

#------------------------------------------------------------------------------

done_testing;

