#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

{
    my $t = Pinto::Tester->new;

    # Check that master stack dir exists in the first place
    $t->path_exists_ok( [qw(stacks master)] );

    # Put archive on the master stack.
    my $archive = make_dist_archive('Dist-1=PkgA~1');
    $t->run_ok( Add => { archives => $archive, author => 'JOHN', no_recurse => 1 } );
    $t->registration_ok('JOHN/Dist-1/PkgA~1/master');

    # Copy the "master" stack to "dev" and make it the default
    $t->run_ok( Copy => { from_stack => 'master', to_stack => 'dev', default => 1 } );
    $t->registration_ok('JOHN/Dist-1/PkgA~1/dev');
    $t->stack_is_default_ok('dev');

    # Delete the "master" stack.
    $t->run_ok( Kill => { stack => 'master' } );
    $t->stack_not_exists_ok('master');

    # The dev stack should still be the same
    $t->registration_ok('JOHN/Dist-1/PkgA~1/dev');
}

#------------------------------------------------------------------------------

{
    my $t = Pinto::Tester->new;

    # Make sure master is the default
    $t->stack_is_default_ok('master');

    # Try killing the default stack
    $t->run_throws_ok(
        Kill => { stack => 'master' },
        qr/Cannot kill the default stack/,
        'Killing default stack throws exception'
    );

    # Is stack still there?
    $t->stack_exists_ok('master');
}

#------------------------------------------------------------------------------

{
    my $t = Pinto::Tester->new( init_args => { no_default => 1 } );
    $t->no_default_stack_ok;

    # Lock the master stack
    $t->run_ok( Lock => { stack => 'master' } );
    $t->stack_is_locked_ok('master');

    # Try killing the locked stack
    $t->run_throws_ok(
        Kill => { stack => 'master' },
        qr/is locked/,
        'Killing locked stack throws exception'
    );

    # Is stack still there?
    $t->stack_exists_ok('master');

    # Try killing locked stack with force
    $t->run_ok( Kill => { stack => 'master', force => 1 } );

    # Is stack still there?
    $t->stack_not_exists_ok('master');
}

#------------------------------------------------------------------------------

done_testing;
