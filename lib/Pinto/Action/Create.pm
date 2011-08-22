package Pinto::Action::Create;

# ABSTRACT: An action to create a new repository

use Moose;

use Path::Class;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw(Pinto::Role::PathMaker);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # Write indexes
    my $master_index_file = $self->idxmgr->master_index->write->file();
    my $local_index_file  = $self->idxmgr->local_index->write->file();

    # Create config dir
    my $config_dir = $self->config->repos->subdir('config');
    $self->mkpath($config_dir);

    # Write config file
    my $config_file = $config_dir->file('pinto.ini');
    $self->config->write_config_file( file => $config_file );

    $self->store->add( file => $master_index_file );
    $self->store->add( file => $local_index_file );
    $self->store->add( file => $config_file );

    $self->add_message('Created a new Pinto repository');

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
