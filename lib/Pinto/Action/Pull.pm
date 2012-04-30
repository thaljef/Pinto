# ABSTRACT: Pull upstream distributions into the repository

package Pinto::Action::Pull;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Pull
         Pinto::Role::PackageImporter );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    $self->_execute($_, $stack) for $self->targets;

    return $self->result;
}

#------------------------------------------------------------------------------

sub _execute {
    my ($self, $target, $stack) = @_;

    my ($dist, $did_pull) = $self->find_or_pull( $target, $stack );
    return if not $dist;

    unless ( $self->norecurse ) {
        my @prereq_dists = $self->pull_prerequisites( $dist, $stack );
        $did_pull += @prereq_dists;
    }

    $self->result->changed if $did_pull;

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
