# ABSTRACT: Delete a stack

package Pinto::Action::Delete;

use Moose;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    $self->repos->delete_stack_filesystem(stack => $stack);
    $stack->delete;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
