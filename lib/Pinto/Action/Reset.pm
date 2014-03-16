# ABSTRACT: Reset stack to a prior revision

package Pinto::Action::Reset;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(throw);
use Pinto::Types qw(StackName StackDefault RevisionID);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName | StackDefault,
    default  => undef,
);

has revision => (
    is       => 'ro',
    isa      => RevisionID,
    required => 1,
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

    my $rev   = $self->repo->get_revision($self->revision);
    my $stack = $self->repo->get_stack($self->stack);
    my $head  = $stack->head;

    throw "Revision $rev is the head of stack $stack"
        if $rev->id == $head->id;

    throw "Revision $rev is not an ancestor of stack $stack"
        if !$rev->is_ancestor_of($head) && !$self->force;

    $stack->update({head => $rev->id});
    $stack->write_index;

    my $format = '%i: %{40}T';
    $self->diag("Stack $stack was " . $head->to_string($format));
    $self->diag("Stack $stack now " . $rev->to_string($format));

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
