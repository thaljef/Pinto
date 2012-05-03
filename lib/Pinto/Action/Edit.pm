# ABSTRACT: Change stack properties

package Pinto::Action::Edit;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Edit );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);
    $stack->mark_as_master if $self->master;
    $stack->set_properties($self->properties);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
