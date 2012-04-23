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

sub _execute {
    my ($self, $target) = @_;

    return $self->_unpin_package($target)
        if $target->isa('Pinto::PackageSpec');

    return $self->_unpin_distribution($target)
        if $target->isa('Pinto::DistributionSpec');

    my $type = ref $target;
    $self->fatal("Don't know how to unpin target of type $type");
}

#------------------------------------------------------------------------------

sub _unpin_package {
    my ($self, $pspec) = @_;

    my ($pkg_name, $stk_name) = ($pspec->name, $self->stack->name);
    my $pkg = $self->repos->get_package( name  => $pkg_name,
                                         stack => $stk_name );

    $self->fatal("Package $pkg_name is not on stack $stk_name")
        if not $pkg;

    my $dist = $pkg->distribution;

    return $self->repos->unpin( distribution => $dist,
                                stack        => $self->stack );
}


#------------------------------------------------------------------------------

sub _unpin_distribution {
   my ($self, $dspec) = @_;

   my $dist = $self->repos->get_distribution(path => $dspec->path);

   $self->fatal("Distribution $dspec does not exist")
       if not $dist;

   return $self->repos->unpin( distribution => $dist,
                               stack        => $self->stack );
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
