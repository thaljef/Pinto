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

sub BUILD {
    my ($self, $args) = @_;

    my $from_stk_name = $self->from_stack;
    $self->fatal("Stack $from_stk_name does not exist")
        if not $self->repos->get_stack(name => $from_stk_name);

    my $to_stk_name = $self->to_stack;
    $self->fatal("Stack $to_stk_name already exists")
        if $self->repos->get_stack(name => $to_stk_name);

    return $self;
}

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
