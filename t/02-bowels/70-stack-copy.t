#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

{
    # Create a new stack...
    my $stk_name = 'dev';
    $t->run_ok( New => { stack => $stk_name } );
    my $stack = $t->pinto->repo->get_stack($stk_name);
    is $stack->name, $stk_name, 'Got correct stack name';

    # Add to the stack...
    my $foo_and_bar_1 = make_dist_archive('FooAndBar-1 = Foo~1; Bar~1');
    $t->run_ok( Add => { author => 'ME', stack => $stk_name, archives => $foo_and_bar_1 } );

    # Note the time of last commit
    my $old_mtime = $stack->refresh->head->utc_time;

    # time passes
    sleep 2;

    # Add more stuff to the stack...
    my $foo_and_bar_2 = make_dist_archive('FooAndBar-2 = Foo~2; Bar~2');
    $t->run_ok( Add => { author => 'ME', stack => $stk_name, archives => $foo_and_bar_2 } );

    # Check that mtime was updated...
    cmp_ok $stack->refresh->head->utc_time, '>', $old_mtime, 'Updated stack mtime';
}

#------------------------------------------------------------------------------

{
    # Copy dev -> qa...
    my $dev_stk_name = 'dev';
    my $qa_stk_name  = 'qa';
    $t->run_ok( Copy => { stack => $dev_stk_name, to_stack => $qa_stk_name } );

    my $dev_stack = $t->pinto->repo->get_stack($dev_stk_name);
    my $qa_stack  = $t->pinto->repo->get_stack($qa_stk_name);

    is $qa_stack->name, $qa_stk_name, 'Got correct stack name';

    is $qa_stack->description, 'Copy of stack dev', 'Got correct stack description';

    is $qa_stack->head->id, $dev_stack->head->id, 'Head of copied stack points to head of original stack';
}

#------------------------------------------------------------------------------

{
    # Copy with extra stuff
    my $dev_stk_name  = 'dev';
    my $xtra_stk_name = 'xtra';
    $t->run_ok(
        Copy => {
            stack  => $dev_stk_name,
            to_stack    => $xtra_stk_name,
            description => 'custom',
            lock        => 1
        }
    );

    my $xtra_stack = $t->pinto->repo->get_stack($xtra_stk_name);

    is $xtra_stack->is_locked,   1,        'Copied stack is locked';
    is $xtra_stack->description, 'custom', 'Copied stack has custom description';
}

#------------------------------------------------------------------------------

{

    # Marking default stack...
    my $master_stack = $t->pinto->repo->get_stack;
    ok defined $master_stack, 'get_stack with no args returned a stack';
    ok $master_stack->is_default, 'master stack is the default stack';

    my $dev_stack = $t->pinto->repo->get_stack('dev');
    ok defined $dev_stack, 'got the dev stack';

    $dev_stack->mark_as_default;
    ok $dev_stack->is_default, 'dev stack is now default';

    # Force reload from DB...
    $master_stack->discard_changes;
    ok !$master_stack->is_default, 'master stack is no longer default';

    throws_ok { $master_stack->is_default(0) } qr/Cannot directly set is_default/,
        'Setting is_default directly throws exception';
}

#------------------------------------------------------------------------------
# Mixed-case stack names...

{

    $t->run_ok(
        New => { stack => 'MixedCase' },
        'Created stack with mixed-case name'
    );

    ok $t->pinto->repo->get_stack('mixedcase'), 'Got stack using name with different case';

    $t->path_exists_ok( [qw( stacks MixedCase)], 'Stack directory name has mixed-case name too' );

}

#------------------------------------------------------------------------------
# Exceptions...

{
    # Copy from a stack that doesn't exist
    $t->run_throws_ok(
        Copy => {
            stack => 'nowhere',
            to_stack   => 'somewhere'
        },
        qr/Stack nowhere does not exist/
    );

    # Copy to a stack that already exists
    $t->run_throws_ok(
        Copy => {
            stack => 'master',
            to_stack   => 'dev'
        },
        qr/Stack dev already exists/
    );

    # Copy to a stack that already exists, but with different case
    $t->run_throws_ok(
        Copy => {
            stack => 'master',
            to_stack   => 'DeV'
        },
        qr/Stack dev already exists/
    );

    # Create stack with invalid name
    $t->run_throws_ok(
        New => { stack => '$bogus@' },
        qr/must be alphanumeric/
    );

    # Copy to stack with invalid name
    $t->run_throws_ok(
        Copy => {
            stack => 'master',
            to_stack   => '$bogus@'
        },
        qr/must be alphanumeric/
    );

    # Copy to stack with no name
    $t->run_throws_ok(
        Copy => {
            stack => 'master',
            to_stack   => ''
        },
        qr/must be alphanumeric/
    );

    # Copy to stack with undef name
    $t->run_throws_ok(
        Copy => {
            stack => 'master',
            to_stack   => undef
        },
        qr/must be alphanumeric/
    );
}

#------------------------------------------------------------------------------

done_testing;

