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

has pin   => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------


with qw( Pinto::Role::Interface::Action::Add
         Pinto::Role::PackageImporter
         Pinto::Role::Attribute::stack );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $dist  = $self->repos->add( archive   => $self->archive,
                                   author    => $self->author );

    $self->repos->register( distribution  => $dist,
                            stack         => $self->stack );

    $self->repos->pin( distribution   => $dist,
                       stack          => $self->stack ) if $self->pin;

    $self->pull_prerequisites( $dist ) unless $self->norecurse;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
