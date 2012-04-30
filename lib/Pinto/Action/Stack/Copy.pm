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

    my $stack = $self->repos->get_stack(name => $self->from_stack);
    my $copy = $stack->copy_deeply({name => $self->to_stack});
    my $description = $self->description || "copy of stack $stack";
    $copy->set_property('description' => $description);
    $copy->touch($stack->last_modified_on);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
