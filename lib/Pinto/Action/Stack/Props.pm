# ABSTRACT: Show stack properties

package Pinto::Action::Stack::Props;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Attribute::out
         Pinto::Role::Attribute::stack );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    my $props = $stack->get_properties;
    while ( my ($prop, $value) = each %{$props} ) {
        print { $self->out } "$prop = $value\n";
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
