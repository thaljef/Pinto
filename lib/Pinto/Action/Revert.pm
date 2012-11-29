# ABSTRACT: Restore stack to a prior revision

package Pinto::Action::Revert;

use Moose;
use MooseX::Types::Moose qw(Int);

use Pinto::Types qw(StackName StackDefault StackObject);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);


has revision => (
    is       => 'ro',
    isa      => Int,
    default  => -1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack   = $self->repo->get_stack($self->stack);
    my $revnum  = $self->_compute_target_revnum($stack);

    $self->_revert($stack, $revnum);
    $self->result->changed if $stack->refresh->has_changed;

    if ($stack->has_changed and not $self->dryrun) {
        my $message = $self->edit_message(stacks => [$stack]);
        $stack->close(message => $message);
        $self->repo->write_index(stack => $stack);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub _compute_target_revnum {
    my ($self, $stack) = @_;

    my $headnum = $stack->head_revision->number;

    my $revnum  = $self->revision;
    $revnum     = ($headnum + $revnum) if $revnum < 0;

    throw "Stack $stack is already at revision 0" if $headnum == 0;

    throw "No such revision $revnum on stack $stack" if $revnum > $headnum;

    throw "Revision $revnum is the head of stack $stack" if $revnum == $headnum;

    return $revnum;
}

#------------------------------------------------------------------------------

sub _revert {
    my ($self, $stack, $revnum) = @_;

    $self->notice("Reverting stack $stack to revision $revnum");

    my $new_head  = $self->repo->open_revision(stack => $stack);
    my $previous_revision = $new_head->previous_revision;

    while ($previous_revision->number > $revnum) {
        $previous_revision->undo;
        $previous_revision = $previous_revision->previous_revision;
    }

    return $self;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $revnum = $self->revision;

    return "Reverted to revision $revnum.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
