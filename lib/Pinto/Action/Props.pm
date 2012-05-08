# ABSTRACT: Show stack properties

package Pinto::Action::Props;

use Moose;
use MooseX::Types::Moose qw(Maybe Str);

use String::Format;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Reporter );

#------------------------------------------------------------------------------

has stack  => (
    is       => 'ro',
    isa      => Maybe[Str],
);


has format => (
    is      => 'ro',
    isa     => Str,
    default => "%n = %v\n",
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    my $props = $stack->get_properties;
    while ( my ($prop, $value) = each %{$props} ) {
        print { $self->out } stringf($self->format, {n => $prop, v => $value});
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
