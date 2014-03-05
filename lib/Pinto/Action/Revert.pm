# ABSTRACT: Revert stack to a prior revision

package Pinto::Action::Revert;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(throw);
use Pinto::Types qw(StackDefault StackName StackObject RevisionID RevisionHead);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has revision => (
    is       => 'ro',
    isa      => RevisionID | RevisionHead,
    default  => undef,
    coerce   => 1,
);

has force => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # Remember that the Committable role has already moved the head
    # forward to a new revision which is a duplicate of the last head.

    my $stack     = $self->stack;
    my $new_head  = $stack->head;
    my $old_head  = ($new_head->parents)[0];

    my $rev = $self->revision
        ? $self->repo->get_revision($self->revision)
        : ($old_head->parents)[0];

    throw "Cannot revert past the root commit"
        if not $rev;

    throw "Revision $rev is the head of stack $stack"
        if $rev eq $old_head;

    throw "Revision $rev is not an ancestor of stack $stack"
        if !$rev->is_ancestor_of($old_head) && !$self->force;

    $new_head->registrations_rs->delete;
    $stack->duplicate_registrations(to => $new_head, from => $rev);

    # We must explicitly mark the stack as changed, snce we injected the
    # registrations directly.  But it is possible that the new state is
    # exactly the same as the old state.  So we use the diff to be sure.

    $stack->diff->is_different
        ? $stack->mark_as_changed
        : throw "Revision $rev is identical to the head of stack $stack";

    return 1;
}

#------------------------------------------------------------------------------

sub generate_message_title {
    my ($self) = @_;

    # TODO: fix duplication...
    my $stack     = $self->stack;
    my $new_head  = $stack->head;
    my $old_head  = ($new_head->parents)[0];

    my $rev = $self->revision
        ? $self->repo->get_revision($self->revision)
        : ($old_head->parents)[0];

    return sprintf "Revert to %s: %s", $rev->uuid_prefix, $rev->message_title;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
