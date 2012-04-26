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

    my $dist;
    my $stk_name = $self->stack;

    if ($target->isa('Pinto::PackageSpec')) {

        my $pkg_name = $target->name;
        my $pkg = $self->repos->get_package(name => $pkg_name, stack => $stk_name)
            or $self->fatal("Package $pkg_name is not on stack $stk_name");

        $dist = $pkg->distribution;
    }
    elsif ($target->isa('Pinto::DistributionSpec')) {

        $dist = $self->repos->get_distribution(path => $target->path)
            or $self->fatal("Distribution $target does not exist");
    }
    else {

        my $type = ref $target;
        $self->fatal("Don't know how to pin target of type $type");
    }


    $self->notice("Unpinning $dist from stack $stk_name");
    $self->repos->unpin(distribution => $dist, stack => $stk_name);

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
