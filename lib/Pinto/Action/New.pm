# ABSTRACT: Create a new empty stack

package Pinto::Action::New;

use Moose;
use MooseX::Types::Moose qw(Str Bool Undef);

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
    isa        => Str | Undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->create_stack(name => $self->stack);
    $stack->set_property(description => $self->description) if $self->description;
    $stack->mark_as_default if $self->default;

    my $message = $self->edit_message(stacks => [$stack]);
    $stack->close(message => $message);

    $self->repo->create_stack_filesystem(stack => $stack);
    $self->repo->write_index(stack => $stack);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    return 'Created stack.';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
