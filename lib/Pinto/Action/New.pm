# ABSTRACT: Create a new empty stack

package Pinto::Action::New;

use Moose;
use MooseX::Aliases;
use MooseX::Types::Moose qw(Str);

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName,
    alias    => 'operative_stack',
    required => 1,
    coerce   => 1,
);


has description => (
    is         => 'ro',
    isa        => Str,
    predicate  => 'has_description',
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Operator );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->create_stack(name => $self->stack);

    $stack->set_property(description => $self->description) if $self->has_description;

    $self->repos->write_index(stack => $stack);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
