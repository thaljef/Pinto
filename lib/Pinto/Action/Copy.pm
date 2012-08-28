# ABSTRACT: An action to create a new stack by copying another

package Pinto::Action::Copy;

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has from_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);


has description => (
    is         => 'ro',
    isa        => Str,
    predicate  => 'has_description',
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $orig = $self->repos->get_stack(name => $self->from_stack);
    my $copy = $self->repos->copy_stack(from => $orig, to => $self->to_stack);

    my $description = $self->description || "copy of stack $orig";
    $copy->set_property(description => $description);
    $copy->touch($orig->last_modified_on);

    $self->repos->write_index(stack => $copy);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
