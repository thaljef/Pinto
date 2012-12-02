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


has target_revision => (
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    builder  => '_build_target_revision',
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub _build_target_revision {
    my ($self) = @_;

    my $stack     = $self->repo->get_stack($self->stack);

    my $revnum    = $self->revision;
    my $headnum   = $stack->head_revision->number;
    my $target    = $revnum < 0 ? ($headnum + $revnum) : $revnum;

    throw "Cannot go beyond revision 0" if $target < 0;

    throw "Revision $target has not happend yet on stack $stack" if $target > $headnum;

    throw "Revision $target is the head of stack $stack" if $target == $headnum;

    return $target;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);
    my $target = $self->target_revision;

    $self->_revert($stack, $target);

    if (not $self->dryrun) {
        my $message = $self->edit_message(stacks => [$stack]);
        $stack->close(message => $message);
        $self->repo->write_index(stack => $stack);
    }

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _revert {
    my ($self, $stack, $target) = @_;

    $self->notice("Reverting stack $stack to revision $target");

    my $new_head  = $self->repo->open_revision(stack => $stack);
    my $previous_revision = $new_head->previous_revision;

    while ($previous_revision->number > $target) {
        $previous_revision->undo;
        $previous_revision = $previous_revision->previous_revision;

        # If our logic is right, then $previous_revision should always exist
        throw "PANIC: Reached end of history" if not defined $previous_revision;
    }

    return $self;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $revnum = $self->target_revision;

    return "Reverted to revision $revnum.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
