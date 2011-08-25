package Pinto::Action::Rebuild;

# ABSTRACT: An action to rebuild the master index of the repository

use Moose;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $self->idxmgr->rebuild_master_index();

    $self->add_message('Rebuilt the index');

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
