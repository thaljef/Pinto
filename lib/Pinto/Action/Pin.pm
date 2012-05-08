# ABSTRACT: Force a package to stay in a stack

package Pinto::Action::Pin;

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Types qw(ArrayRefOfPkgsOrDists);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => Str,
);


has targets => (
    isa      => ArrayRefOfPkgsOrDists,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    $self->_execute($_, $stack) for $self->targets;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _execute {
    my ($self, $target, $stack) = @_;

    my $dist;
    if ($target->isa('Pinto::PackageSpec')) {

        my $pkg_name = $target->name;
        my $pkg = $self->repos->get_package(name => $pkg_name, stack => $stack)
            or throw "Package $pkg_name is not on stack $stack";

        $dist = $pkg->distribution;
    }
    elsif ($target->isa('Pinto::DistributionSpec')) {

        $dist = $self->repos->get_distribution(path => $target->path)
            or throw "Distribution $target does not exist";
    }
    else {

        my $type = ref $target;
        throw "Don't know how to pin target of type $type";
    }


    $self->notice("Pinning $dist on stack $stack");
    $dist->pin(stack => $stack);

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
