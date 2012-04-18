# ABSTRACT: Delete a stack

package Pinto::Action::Stack::Remove;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Stack::Remove );

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;

    my $stack_name = $self->stack;

    $self->fatal( 'You cannot remove the default stack' )
        if $stack_name eq 'default';

    my $stack = $self->repos->get_stack( name => $stack_name )
        or $self->fatal("Stack $stack_name does not exist");

    $self->info("Removing stack $stack");

    $stack->delete;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
