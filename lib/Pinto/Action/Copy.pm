# ABSTRACT: An action to create a new stack by copying another

package Pinto::Action::Copy;

use Moose;
use MooseX::Types::Moose qw(Str);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

has from_stack => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has description => (
    is         => 'ro',
    isa        => Str,
    predicate  => 'has_description',
);

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
