# ABSTRACT: Force a package to stay in a stack

package Pinto::Action::Pin;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(SpecList StackName StackDefault StackObject);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);


has targets => (
    isa      => SpecList,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);
    $self->_pin($_, $stack) for $self->targets;

    return $self->result if $self->dryrun or $stack->has_not_changed;

    my $message = $self->edit_message(stacks => [$stack]);
    $stack->commit(message => $message);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _pin {
    my ($self, $spec, $stack) = @_;

    my $dist = $self->repo->get_distribution_by_spec(spec => $spec, stack => $stack);

    throw "$spec does not exist in the repository" if not defined $dist;

    $self->notice("Pinning distribution $dist to stack $stack");

    $stack->pin(distribution => $dist);

    return;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $targets  = join ', ', $self->targets;

    return "Pinned ${targets}.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
