# ABSTRACT: Delete a stack

package Pinto::Action::Delete;

use Moose;
use MooseX::Aliases;
use MooseX::Types::Moose qw(Str);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    alias    => 'operative_stack',
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Operator );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);
    $stack->delete;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
