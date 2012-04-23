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

sub BUILD {
    my ($self, $args) = @_;

    my $stk_name = $self->stack;
    $self->fatal("Stack $stk_name does not exist")
        if not $self->repos->get_stack(name => $stk_name);

    $self->fatal('You cannot remove the default stack')
        if $stk_name eq 'default';

    return $self;
}

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
