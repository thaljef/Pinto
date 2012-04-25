# ABSTRACT: An action to create a new stack by copying another

package Pinto::Action::Stack::Copy;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Stack::Copy );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $self->repos->copy_stack( from        => $self->from_stack,
                              to          => $self->to_stack,
                              description => $self->description );

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
