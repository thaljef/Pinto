# ABSTRACT: Loosen a package that has been pinned

package Pinto::Action::Unpin;

use Moose;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Unpin );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $self->_execute($_) for $self->targets;

    return $self->result->changed;
}

#------------------------------------------------------------------------------
# TODO: Consolidate package and dist pinning to one method.

sub _execute {
    my ($self, $target) = @_;

    return $self->_unpin_package($target, $stack)
        if $target->isa('Pinto::PackageSpec');

    return $self->_unpin_distribution($target, $stack)
        if $target->isa('Pinto::DistributionSpec');

    my $type = ref $target;
    $self->fatal("Don't know how to unpin target of type $type");
}

#------------------------------------------------------------------------------

sub _unpin_package {
    my ($self, $pspec, $stack) = @_;

    my $pkg_name = $pspec->name;
    my $pkg = $self->repos->get_package( name  => $pkg_name,
                                         stack => $stack );

    $self->fatal("Package $pkg_name is not on stack $stack")
        if not $pkg;

    my $dist = $pkg->distribution;
    $self->notice("Unpinning $dist from stack $stack");

    return $self->repos->unpin( distribution => $dist,
                                stack        => $stack );
}


#------------------------------------------------------------------------------

sub _unpin_distribution {
   my ($self, $dspec, $stack) = @_;

   my $dist = $self->repos->get_distribution(path => $dspec->path);

   $self->fatal("Distribution $dspec does not exist")
       if not $dist;

   $self->notice("Unpinning $dist from stack $stack");

   return $self->repos->unpin( distribution => $dist,
                               stack        => $stack );
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
