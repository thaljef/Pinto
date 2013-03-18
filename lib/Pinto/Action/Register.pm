# ABSTRACT: Register packages from existing archives on a stack

package Pinto::Action::Register;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Exception qw(throw);
use Pinto::Types qw(DistSpecList);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets   => (
    isa      => DistSpecList,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);


has pin => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------


sub execute {
    my ($self) = @_;

    my $stack = $self->stack;

    my @dists = map { $self->_register($_, $stack) } $self->targets;
    
    return @dists;
}

#------------------------------------------------------------------------------

sub _register {
    my ($self, $spec, $stack) = @_;

    my $dist  = $self->repo->get_distribution(spec => $spec);

    throw "Distribution $spec is not in the repository" if not defined $dist;

    $self->notice("Registering distribution $dist on stack $stack");

    my $did_register = $dist->register(stack => $stack, pin => $self->pin);

    $self->warning("Distribution $dist is already registered on stack $stack");

    return $did_register ? $dist : ();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
