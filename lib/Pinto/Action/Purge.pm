# ABSTRACT: Remove all distributions from the repository

package Pinto::Action::Purge;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Interface::Action::Purge );

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $dists = $self->repos->db->select_distributions();

    my $count = $dists->count();
    $self->notice("Removing all $count distributions from the repository");

    my $removed = 0;
    while ( my $dist = $dists->next() ) {
        $self->repos->remove_distribution($dist);
        $removed++
    }

    $self->add_message("Purged all $removed distributions" ) if $removed;

    return $removed;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
