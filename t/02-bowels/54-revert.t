#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

subtest "Revert to previous revision" => sub {

    my $t = Pinto::Tester->new;

    $t->populate('AUTHOR/Foo-1=Foo~1');
    my $reg1 = 'AUTHOR/Foo-1/Foo~1';
    my $rev1 = $t->get_stack->head;
    $t->registration_ok($reg1);

    $t->populate('AUTHOR/Foo-2=Foo~2');
    my $reg2 = 'AUTHOR/Foo-2/Foo~2';
    my $rev2 = $t->get_stack->head;
    $t->registration_ok($reg2);

    $t->run_ok(Revert => {});
    isnt $t->get_stack->head->id, $rev2->id, 'Created a new revision';
    $t->registration_ok($reg1, 'Reverted to rev1');
};

#------------------------------------------------------------------------------

subtest "Revert to specific revision" => sub {

    my $t = Pinto::Tester->new;

    $t->populate('AUTHOR/Foo-1=Foo~1');
    my $reg1 = 'AUTHOR/Foo-1/Foo~1';
    my $rev1 = $t->get_stack->head;
    $t->registration_ok($reg1);

    $t->populate('AUTHOR/Foo-2=Foo~2');
    my $reg2 = 'AUTHOR/Foo-2/Foo~2';
    my $rev2 = $t->get_stack->head;
    $t->registration_ok($reg2);

    $t->run_ok(Revert => {revision => "$rev1"});
    isnt $t->get_stack->head->id, $rev2->id, 'Created a new revision';
    $t->registration_ok($reg1, 'Reverted to rev1');
};

#------------------------------------------------------------------------------

subtest "Revert to root commit" => sub {

    my $t = Pinto::Tester->new;

    $t->populate('AUTHOR/Foo-1=Foo~1');
    my $reg1 = 'AUTHOR/Foo-1/Foo~1';
    my $rev1 = $t->get_stack->head;
    $t->registration_ok($reg1);

    $t->populate('AUTHOR/Foo-2=Foo~2');
    my $reg2 = 'AUTHOR/Foo-2/Foo~2';
    my $rev2 = $t->get_stack->head;
    $t->registration_ok($reg2);

    $t->run_ok(Revert => {revision => "0000"});
    $t->stack_is_empty_ok;
};

#------------------------------------------------------------------------------

subtest "Exceptions" => sub {

    my $t = Pinto::Tester->new;
    my $rev0 = $t->get_stack->head;

    $t->run_throws_ok(Revert => {revision => "$rev0"},
        qr/is the head of stack/, "Cannot revert to the current head");

    $t->run_throws_ok(Revert => {},
        qr/Cannot revert past the root/, "Cannot revert beyond root");
};

#------------------------------------------------------------------------------

done_testing;

