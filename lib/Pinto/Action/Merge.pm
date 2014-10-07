# ABSTRACT: Join two stack histories together

package Pinto::Action::Merge;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(throw);
use Pinto::Types qw(StackName StackObject StackDefault);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);


has into_stack => (
    is       => 'ro',
    isa      => StackName | StackObject | StackDefault,
    default  => undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);
    my $from_head  = $stack->head;

    my $into_stack = $self->repo->get_stack($self->into_stack);
    my $into_head  = $into_stack->head;

    return 1 && $self->warning("Both stacks are the same ($into_head)")
        if $into_head->id == $from_head->id;

    throw "Recursive merge is not supported yet"
        unless $from_head->is_descendant_of($into_head);

    $into_stack->update({head => $from_head->id});
    $into_stack->write_index;

    my $format = '%i: %{40}T';
    $self->diag("Fast-forward...");
    $self->diag("Stack $into_stack was " . $into_head->to_string($format));
    $self->diag("Stack $into_stack now " . $from_head->to_string($format));

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
