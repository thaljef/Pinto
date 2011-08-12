package Pinto::Action::Create;

# ABSTRACT: An action to create a new repository

use Moose;

use Carp;
use Path::Class;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # This is a terrible hack.  We are relying on Pinto::Index
    # to create the files for us.

    my $master_index_file = $self->idxmgr->master_index->write->file();
    my $local_index_file  = $self->idxmgr->local_index->write->file();

    $self->store->add( file => $master_index_file );
    $self->store->add( file => $local_index_file );

    $self->add_message('Created a new Pinto repository');
    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
