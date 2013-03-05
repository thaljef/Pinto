# ABSTRACT: Unregister packages from a stack

package Pinto::Action::Pop;

use Moose;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Exception qw(throw);
use Pinto::Types qw(SpecList StackName StackDefault StackObject);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has targets   => (
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


has force => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------


sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack)->start_revision;
    $self->_pop($_, $stack) for $self->targets;

    return $self->result if $self->dryrun or $stack->has_not_changed;

    my $message = $self->edit_message(stack => $stack);
    $stack->commit_revision(message => $message);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _pop {
    my ($self, $target, $stack) = @_;

    my $dist = $stack->get_distribution(spec => $target);
    throw "$target is not registered on stack $stack" if not defined $dist;

    $dist->unregister(stack => $stack, force => $self->force);

    return;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $targets  = join ' ', $self->targets;
    my $force    = $self->force ? ' with force' : '';

    return "Popped$force $targets.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
