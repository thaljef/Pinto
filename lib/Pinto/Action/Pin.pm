# ABSTRACT: Force a package to stay in a stack

package Pinto::Action::Pin;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Pin );

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

    return $self->_pin_package($target, $stack)
        if $target->isa('Pinto::PackageSpec');

    return $self->_pin_distribution($target, $stack)
        if $target->isa('Pinto::DistributionSpec');

    my $type = ref $target;
    $self->fatal("Don't know how to pin target of type $type");
}

#------------------------------------------------------------------------------

sub _pin_package {
    my ($self, $pspec, $stack) = @_;

    my $pkg_name = $pspec->name;
    my $pkg = $self->repos->get_package( name  => $pkg_name,
                                         stack => $stack->name );

    $self->fatal("Package $pkg_name is not on stack $stack")
        if not $pkg;

    my $dist = $pkg->distribution;
    $self->notice("Pinning $dist on stack $stack");

    return $self->repos->pin( distribution => $dist,
                              stack        => $stack );
}

#------------------------------------------------------------------------------

sub _pin_distribution {
   my ($self, $dspec, $stack) = @_;

   my $dist = $self->repos->get_distribution(path => $dspec->path);

   $self->fatal("Distribution $dspec does not exist")
       if not $dist;

   $self->notice("Pinning $dist on stack $stack");

   return $self->repos->pin( distribution => $dist,
                             stack        => $stack );
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
