# ABSTRACT: Pull an upstream distribution into the repository

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

sub BUILD {
    my ($self, $args) = @_;

    my $stk_name = $self->stack;
    $self->fatal("Stack $stk_name does not exist")
        if not $self->repos->get_stack(name => $stk_name);

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my ($dist, $did_pull) = $self->find_or_pull( $self->target );
    return $self->result if not $dist;

    unless ( $self->norecurse ) {
        my @prereq_dists = $self->pull_prerequisites( $dist );
        $did_pull += @prereq_dists;
    }

    $self->result->changed if $did_pull;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
