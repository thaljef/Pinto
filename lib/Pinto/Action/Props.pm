# ABSTRACT: Show stack properties

package Pinto::Action::Props;

use Moose;
use MooseX::Types::Moose qw(Undef Maybe);

use String::Format;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Reporter );

#------------------------------------------------------------------------------

has stack  => (
    is        => 'ro',
    isa       => StackName | Undef,
    default   => undef,
    coerce    => 1,
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
