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

sub BUILD {
    my ($self) = @_;

    # TODO: Should this check also be placed in the PackageStack too?
    # I think we also want it here so we can do it as early as possible

    $self->fatal('You cannot place pins on the default stack')
        if $self->stack->name eq 'default';

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;
    my $target = $self->target;

    if ( $target->isa('Pinto::PackageSpec') ){
        $self->_pin_package($target);
    }
    elsif ( $target->isa('Pinto::DistributionSpec') ){
        $self->_pin_distribution($target);
    }
    else {
        my $type = ref $target;
        confess "Don't know how to pin target type $type";
    }

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _pin_package {
    my ($self, $pspec) = @_;

    my ($pkg_name, $stk_name) = ($pspec->name, $self->stack->name);
    my $pkg_stk = $self->repos->get_stack_member( package => $pkg_name,
                                                  stack   => $stk_name );

    confess "Package $pkg_name is not on stack $stk_name"
        if not $pkg_stk;

    retun $self->repos->pin( package => $pkg_stk->package,
                             stack   => $self->stack );
}

#------------------------------------------------------------------------------

sub _pin_distribution {
   my ($self, $dspec) = @_;

   my $dist = $self->repos->get_distribution(path => $dspec->path);

   confess "Distribution $dspec does not exist"
       if not $dist;

   return $self->repos->pin( distribution => $dist,
                             stack        => $self->stack );
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
