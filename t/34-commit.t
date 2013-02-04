#!perl

#------------------------------------------------------------------------------

package Pinto::Action::Fake;

use Moose;

extends 'Pinto::Action';
with    'Pinto::Role::Committable';

sub execute { 
	my $self = shift;
	my $stack = $self->repo->get_stack;
	my $message = $self->edit_message;
	$stack->commit(message => $message);
	return $self->result->changed; 
}

sub message_title { 
	return 'my title';
}

no Moose;

#------------------------------------------------------------------------------

package main;

use strict;
use warnings;

use Test::More;
use Pinto::Tester;
use Pinto::Globals;

#------------------------------------------------------------------------------

local $Pinto::Globals::current_username = 'ME';

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {});
	my $stack = $t->pinto->repo->get_stack;
	my $commit = $stack->head;

	is ($commit->username, 'ME', 'Revision was committed by ME');
	is ($commit->message, 'my title', 'Message is title only no commit message specified');
	is ($commit->message_body, '', 'Message body is empty when no commit message specified');
	is ($commit->message_title, 'my title', 'Got message title');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {use_default_message => 1});
	my $stack  = $t->pinto->repo->get_stack;
	my $commit = $stack->head;

	is ($commit->message, 'my title', 'Message is title only when use_default_message');
	is ($commit->message_body, '', 'Message body is empty when use_default_message');
	is ($commit->message_title, 'my title', 'Got message title');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {message => '  '});
	my $stack  = $t->pinto->repo->get_stack;
	my $commit = $stack->head;

	is ($commit->message, 'my title', 'Message is title only when specified message was whitespace or empty');
	is ($commit->message_body, '', 'Message body is empty when specified message was whitespace or empty');
	is ($commit->message_title, 'my title', 'Got message title');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {message => 'my message'});
	my $stack  = $t->pinto->repo->get_stack;
	my $commit = $stack->head;

	is ($commit->message, 'my message', 'Got custom commit message when specified');
	is ($commit->message_body, '', 'Message body is empty when specified message has title only');
	is ($commit->message_title, 'my message', 'Got message title');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {message => "  my title  \n\nmy body  "});
	my $stack  = $t->pinto->repo->get_stack;
	my $commit = $stack->head;

	is ($commit->message, "  my title  \n\nmy body  ", 'Got custom commit message when specified');
	is ($commit->message_body, 'my body', 'Got message body');
	is ($commit->message_title, 'my title', 'Got message title');
}

#------------------------------------------------------------------------------

done_testing;

