# ABSTRACT: Loosen a package that has been pinned

package Pinto::Action::Unpin;

use Moose;

use Pinto::Types qw(SpecList StackName StackDefault StackObject);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has targets => (
    isa      => SpecList,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);


has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack)->open;
    $self->_unpin($_, $stack) for $self->targets;
    return $self->result if $self->dryrun or $stack->has_not_changed;

    my $message = $self->edit_message(stacks => [$stack]);
    $stack->close(message => $message);
    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _unpin {
    my ($self, $spec, $stack) = @_;

    my $dist = $self->repo->get_distribution_by_spec(spec => $spec, stack => $stack);

    throw "$spec does not exist in the repository" if not defined $dist;

    $self->notice("Unpinning distribution $dist from stack $stack");

    $stack->unpin(distribution => $dist);

    return;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $targets  = join ', ', $self->targets;

    return "Unpinned ${targets}.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
