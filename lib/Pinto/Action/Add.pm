# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::Types::Moose qw(Bool);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------


with qw( Pinto::Role::Interface::Action::Add
         Pinto::Role::PackageImporter );

#------------------------------------------------------------------------------

sub BUILD {
    my ($self, $args) = @_;

    my @missing = grep { not -e $_ } $self->archives;
    $self->error("Archive $_ does not exist") for @missing;

    my @unreadable = grep { -e $_ and not -r $_ } $self->archives;
    $self->error("Archive $_ is not readable") for @unreadable;

    $self->fatal("Some archives are missing or unreadable")
      if @missing or @unreadable;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $self->_execute($_) for $self->archives;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _execute {
    my ($self, $archive) = @_;

    my $dist  = $self->repos->add( archive   => $archive,
                                   author    => $self->author );

    $self->repos->register( distribution  => $dist,
                            stack         => $self->stack );

    $self->repos->pin( distribution   => $dist,
                       stack          => $self->stack ) if $self->pin;

    $self->pull_prerequisites( $dist ) unless $self->norecurse;

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
