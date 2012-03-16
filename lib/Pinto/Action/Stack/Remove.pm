package Pinto::Action::Stack::Remove;

# ABSTRACT: An action to delete a stack

use Moose;

use MooseX::Types::Moose qw(Str);
use Pinto::Types qw(StackName);

use Pinto::Exceptions qw(throw_fatal);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attributes

has stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------
# Methods

override execute => sub {
    my ($self) = @_;

    my $stack_name = $self->stack();

    $self->fatal( 'You cannot remove the default stack' )
        if $stack_name eq 'default';

    my $stack = $self->repos->get_stack( name => $stack_name )
        or $self->fatal("Stack $stack_name does not exist");

    $self->note("Removing stack $stack");

    $stack->delete();

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
