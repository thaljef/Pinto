# ABSTRACT: Create a new empty stack

package Pinto::Action::Stack::Create;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Stack::Create );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $self->repos->create_stack( name        => $self->stack,
                                description => $self->description );

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__