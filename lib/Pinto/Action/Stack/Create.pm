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

    my $stack_name = $self->stack;

    $self->repos->get_stack( name => $stack_name )
        and $self->fatal("Stack $stack_name already exists");

    $self->info("Creating stack $stack_name");

    my $attrs = { name        => $stack_name,
                  description => $self->description };

    $self->repos->db->create_stack( $attrs );

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
