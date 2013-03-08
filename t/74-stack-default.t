#!perl


use Test::More;
use Test::Exception;
use Pinto::Tester;

#------------------------------------------------------------------------------

{

	my $t = Pinto::Tester->new;
	my $master_stack = $t->pinto->repo->get_stack('master');
	is ($master_stack->is_default, 1, 'master stack is the default');

	$t->run_ok(New => {stack => 'dev'});
	my $dev_stack = $t->pinto->repo->get_stack('dev');
	is ($dev_stack->is_default, 0, 'dev stack is not the default');

	$t->run_ok(Default => {stack => 'dev'});
	is ($master_stack->refresh->is_default, 0, 'master stack is no longer default');
	is ($dev_stack->refresh->is_default, 1, 'dev stack is the new default');

	$t->run_ok(Default => {none => 1});
	is ($master_stack->refresh->is_default, 0, 'master stack is still not default');
	is ($dev_stack->refresh->is_default, 0, 'dev stack is not the default either');

	throws_ok {$t->pinto->repo->get_stack} qr/default stack has not been set/, 
		'There is no default stack at all';
}

#------------------------------------------------------------------------------

done_testing;

