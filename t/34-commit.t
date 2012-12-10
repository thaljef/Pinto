#!perl

#------------------------------------------------------------------------------

package Pinto::Action::Fake;

use Moose;

extends 'Pinto::Action';
with    'Pinto::Role::Committable';

sub execute { 
	my $self = shift; 
	my $stack = $self->repo->open_stack;
	my $message = $self->edit_message; 
	$stack->close(message => $message);
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

local $Pinto::Globals::current_user = 'ME';

my $t = Pinto::Tester->new_with_stack;

#------------------------------------------------------------------------------

{
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;

	is ($revision->number, 0, 'First revision is 0');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;


	is ($revision->number, 1, 'First commit is revision 0');
	is ($revision->kommit->username, 'ME', 'Revision was committed by ME');
	is ($revision->kommit->message, 'my title', 'Message is title only no commit message specified');
	is ($revision->kommit->message_body, '', 'Message body is empty when no commit message specified');
	is ($revision->kommit->message_title, 'my title', 'Got message title');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {use_default_message => 1});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;

	is ($revision->number, 2, 'Next revision number');
	is ($revision->kommit->message, 'my title', 'Message is title only when use_default_message');
	is ($revision->kommit->message_body, '', 'Message body is empty when use_default_message');
	is ($revision->kommit->message_title, 'my title', 'Got message title');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {message => '  '});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;

	is ($revision->number, 3, 'Next revision number');
	is ($revision->kommit->message, 'my title', 'Message is title only when specified message was whitespace or empty');
	is ($revision->kommit->message_body, '', 'Message body is empty when specified message was whitespace or empty');
	is ($revision->kommit->message_title, 'my title', 'Got message title');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {message => 'my message'});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;

	is ($revision->number, 4, 'Next revision number');
	is ($revision->kommit->message, 'my message', 'Got custom commit message when specified');
	is ($revision->kommit->message_body, '', 'Message body is empty when specified message has title only');
	is ($revision->kommit->message_title, 'my message', 'Got message title');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {message => "  my title  \n\nmy body  "});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;

	is ($revision->number, 5, 'Next revision number');
	is ($revision->kommit->message, "  my title  \n\nmy body  ", 'Got custom commit message when specified');
	is ($revision->kommit->message_body, 'my body', 'Got message body');
	is ($revision->kommit->message_title, 'my title', 'Got message title');
}

#------------------------------------------------------------------------------

done_testing;

