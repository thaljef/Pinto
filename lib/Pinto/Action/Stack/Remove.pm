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


sub execute {
    my ($self) = @_;

    $self->repos->remove_stack( name => $self->stack );

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
