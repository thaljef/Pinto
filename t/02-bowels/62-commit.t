#!perl

#------------------------------------------------------------------------------

package Pinto::Action::Fake;

use Moose;

extends 'Pinto::Action';
with 'Pinto::Role::Committable';

sub execute {
    my $self = shift;

    # To bypass assert_has_changed() when committed
    $self->stack->head->update( { has_changes => 1 } );

    return qw(Foo Bar Baz);
}

no Moose;

#------------------------------------------------------------------------------

package main;

use strict;
use warnings;

use Test::More;

use Pinto::Globals;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

local $Pinto::Globals::current_username = 'ME';

my $t           = Pinto::Tester->new;
my $faked_title = 'Fake Bar, Baz, Foo';

#------------------------------------------------------------------------------

{
    note "Specified nothing";

    $t->run_ok( Fake => {} );
    my $stack    = $t->pinto->repo->get_stack;
    my $revision = $stack->head;

    is( $revision->username,      'ME',         'Revision was committed by ME' );
    is( $revision->message_title, $faked_title, 'Message has correct title' );
    is( $revision->message_body,  '',           'Message body is empty' );
    is( $revision->message,       $faked_title, 'Message is title only' );
}

#------------------------------------------------------------------------------

{
    note "Specified use_default_message";

    $t->run_ok( Fake => { use_default_message => 1 } );
    my $stack    = $t->pinto->repo->get_stack;
    my $revision = $stack->head;

    is( $revision->username,      'ME',         'Revision was committed by ME' );
    is( $revision->message_title, $faked_title, 'Message has correct title' );
    is( $revision->message_body,  '',           'Message body is empty' );
    is( $revision->message,       $faked_title, 'Message is title only' );
}

#------------------------------------------------------------------------------

{
    note "Specified message is empty (or whitespace) string";

    $t->run_ok( Fake => { message => '  ' } );
    my $stack    = $t->pinto->repo->get_stack;
    my $revision = $stack->head;

    is( $revision->username,      'ME',         'Revision was committed by ME' );
    is( $revision->message_title, $faked_title, 'Message has correct title' );
    is( $revision->message_body,  '',           'Message body is empty' );
    is( $revision->message,       $faked_title, 'Message is title only' );
}

#------------------------------------------------------------------------------

{

    note "Specified custom (non-empty) message";

    $t->run_ok( Fake => { message => 'my message' } );
    my $stack    = $t->pinto->repo->get_stack;
    my $revision = $stack->head;

    is( $revision->message,       'my message', 'Got custom commit message when specified' );
    is( $revision->message_body,  '',           'Message body is empty when specified message has title only' );
    is( $revision->message_title, 'my message', 'Got message title' );
}

#------------------------------------------------------------------------------

{
    note "Specified custom message containing title and body regions";

    $t->run_ok( Fake => { message => "  my title  \n\nmy body  " } );
    my $stack    = $t->pinto->repo->get_stack;
    my $revision = $stack->head;

    is( $revision->message,       "  my title  \n\nmy body  ", 'Got custom commit message when specified' );
    is( $revision->message_body,  'my body',                   'Got message body' );
    is( $revision->message_title, 'my title',                  'Got message title' );
}

#------------------------------------------------------------------------------

done_testing;

