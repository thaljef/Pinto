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

sub message_primer { 
	return 'my primer';
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

local $Pinto::Globals::is_interactive = 0;
local $Pinto::Globals::current_user = 'ME';

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------
# is ($revision->number, 1, 'First commit (after creating stack) is revision 1');

{
	$t->run_ok(Fake => {});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;


	is ($revision->number, 1, 'First commit (after creating stack) is revision 1');
	is ($revision->committed_by, 'ME', 'Revision was committed by ME');
	is ($revision->message, 'my primer', 'Got primer when no commit message specified');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {use_default_message => 1});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;

	is ($revision->number, 2, 'Next revision number');
	is ($revision->message, 'my primer', 'Got primer when use_default_message');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {message => ''});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;

	is ($revision->number, 3, 'Next revision number');
	is ($revision->message, 'my primer', 'Got primer when message is whitespace or empty');
}

#------------------------------------------------------------------------------

{
	$t->run_ok(Fake => {message => 'my message'});
	my $stack = $t->pinto->repo->get_stack;
	my $revision = $stack->head_revision;

	is ($revision->number, 4, 'Next revision number');
	is ($revision->message, 'my message', 'Got custom commit message when specified');
}

#------------------------------------------------------------------------------

done_testing;

