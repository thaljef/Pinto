# ABSTRACT: Remove all distributions from the repository

package Pinto::Action::Purge;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Purge );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $dists = $self->repos->db->select_distributions;
    my $count = $dists->count;

    if (not $count) {
        $self->info('Repository contains no distributions');
        return $self->result;
    }

    $self->notice("Purging all $count distributions from the repository");

    while ( my $dist = $dists->next ) {
        $self->repos->remove_distribution(dist => $dist);
    }

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
