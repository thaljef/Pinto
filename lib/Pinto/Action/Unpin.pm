# ABSTRACT: Loosen a package that has been pinned

package Pinto::Action::Unpin;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(throw);
use Pinto::Types qw(SpecList);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => SpecList,
    traits   => [qw(Array)],
    handles  => { targets => 'elements' },
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->stack;

    my @dists = map { $self->_unpin( $_, $stack ) } $self->targets;

    return @dists;
}

#------------------------------------------------------------------------------

sub _unpin {
    my ( $self, $target, $stack ) = @_;

    my $dist = $stack->get_distribution( target => $target );

    throw "$target is not registered on stack $stack" if not defined $dist;

    $self->notice("Unpinning distribution $dist from stack $stack");

    my $did_unpin = $dist->unpin( stack => $stack );

    $self->warning("Distribution $dist is not pinned to stack $stack") unless $did_unpin;

    return $did_unpin ? $dist : ();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
