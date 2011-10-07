package Pinto::Action::Clean;

# ABSTRACT: Remove all outdated distributions from the repository

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Methods

override execute => sub {
    my ($self) = @_;

    my $outdated = $self->db->get_all_outdated_distributions();
    my $removed  = 0;

    while ( my $dist = $outdated->next() ) {
        my $path = $dist->path();
        my $file = $dist->archive( $self->config->repos() );

        $self->db->remove_distribution($dist);
        $self->store->remove(file => $file);

        $self->add_message( "Removed distribution $path" );
        $removed++;
    }

    return $removed;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
