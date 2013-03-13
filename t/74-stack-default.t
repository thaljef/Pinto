#!perl

use Test::More;
use Test::Exception;
use Pinto::Tester;

#------------------------------------------------------------------------------

{
	my $t = Pinto::Tester->new;
	$t->stack_is_default_ok('master');

	$t->run_ok(New => {stack => 'dev'});
	$t->stack_is_not_default_ok('dev');

	$t->run_ok(Default => {stack => 'dev'});
	$t->stack_is_default_ok('dev');
	$t->stack_is_not_default_ok('master');

	$t->run_ok(Default => {none => 1});
	$t->stack_is_not_default_ok('master');
	$t->stack_is_not_default_ok('dev');
	$t->no_default_stack_ok;

	throws_ok {$t->pinto->repo->get_stack} 
		qr/default stack has not been set/, 
			'There is no default stack at all';

	$t->path_not_exists_ok( [qw(modules)] );
}

#------------------------------------------------------------------------------

done_testing;

