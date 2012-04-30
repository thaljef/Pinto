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

    my $stack   = $self->repos->get_stack(name => $self->from_stack, croak => 1);
    my $changes = {name => $self->to_stack, description => $self->description};
    my $clone   = $stack->copy($changes);

    $stack->copy_members($clone);
    $clone->touch($stack->mtime);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
