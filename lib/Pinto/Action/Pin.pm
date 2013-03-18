# ABSTRACT: Force a package to stay in a stack

package Pinto::Action::Pin;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(SpecList);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => SpecList,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->stack;

    my @dists = map { $self->_pin($_, $stack) } $self->targets;

    return @dists;
}

#------------------------------------------------------------------------------

sub _pin {
    my ($self, $target, $stack) = @_;

    my $dist = $stack->get_distribution(spec => $target);

    throw "$target is not registered on stack $stack" if not defined $dist;

    $self->notice("Pinning distribution $dist to stack $stack");

    my $did_pin = $dist->pin(stack => $stack);

    return $did_pin ? $dist : ();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
