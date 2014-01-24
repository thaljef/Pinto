# ABSTRACT: Unregister packages from a stack

package Pinto::Action::Unregister;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(throw);
use Pinto::Types qw(TargetList);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => TargetList,
    traits   => [qw(Array)],
    handles  => { targets => 'elements' },
    required => 1,
    coerce   => 1,
);

has force => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->stack;

    my @dists = map { $self->_unregister( $_, $stack ) } $self->targets;

    return @dists;
}

#------------------------------------------------------------------------------

sub _unregister {
    my ( $self, $target, $stack ) = @_;

    my $dist = $stack->get_distribution( target => $target );

    throw "Target $target is not in the repository" if not defined $dist;

    $self->notice("Unregistering distribution $dist from stack $stack");

    my $did_unregister = $dist->unregister( stack => $stack, force => $self->force );

    return $did_unregister ? $dist : ();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
