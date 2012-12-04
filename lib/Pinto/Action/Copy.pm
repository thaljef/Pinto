# ABSTRACT: Create a new stack by copying another

package Pinto::Action::Copy;

use Moose;
use MooseX::Types::Moose qw(Str Bool Undef);

use Pinto::Types qw(StackName StackObject);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has from_stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
);


has default => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has description => (
    is         => 'ro',
    isa        => Str | Undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $orig = $self->repo->get_stack($self->from_stack);
    my $copy = $self->repo->copy_stack(from => $orig, to => $self->to_stack);

    my $description = $self->description || "Copy of stack $orig.";
    $copy->set_property(description => $description);

    $copy->mark_as_default if $self->default;

    $self->repo->create_stack_filesystem(stack => $copy);
    $self->repo->write_index(stack => $copy);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
