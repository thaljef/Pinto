# ABSTRACT: Create a new empty stack

package Pinto::Action::New;

use Moose;
use MooseX::Types::Moose qw(Str Bool);

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
);


has default => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has description => (
    is         => 'ro',
    isa        => Str,
    predicate  => 'has_description',
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->create_stack(name => $self->stack);
    $stack->set_property(description => $self->description) if $self->has_description;

    $stack->close(message => $self->edit_message);

    $stack->mark_as_default if $self->default;

    $self->repos->create_stack_filesystem(stack => $stack);
    $self->repos->write_index(stack => $stack);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub message_primer {
    my ($self) = @_;

    my $stack = $self->stack;

    return "Created new stack $stack.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
