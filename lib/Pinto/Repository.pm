package Pinto::Repository;

# ABSTRACT: Coordinates the database, files, and indexes

use Moose;

use Class::Load;

use Pinto::Database;
use Pinto::IndexCache;
use Pinto::Exceptions qw(throw_fatal);
use Pinto::Types qw(Dir);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has db => (
    is         => 'ro',
    isa        => 'Pinto::Database',
    handles    => [ qw(write_index select_distributions select_packages) ],
    lazy_build => 1,
);


has store => (
    is         => 'ro',
    isa        => 'Pinto::Store',
    handles    => [ qw(initialize commit tag) ],
    lazy_build => 1,
);


has cache => (
    is         => 'ro',
    isa        => 'Pinto::IndexCache',
    lazy_build => 1,
);


has root_dir => (
    is         => 'ro',
    isa        => Dir,
    default    => sub { $_[0]->config->root_dir },
    init_arg   => undef,
    lazy       => 1,
);

#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable );

#-------------------------------------------------------------------------------
# Builders

sub _build_db {
    my ($self) = @_;

    return Pinto::Database->new( config => $self->config(),
                                 logger => $self->logger() );
}

#-------------------------------------------------------------------------------

sub _build_store {
    my ($self) = @_;

    my $store_class = $self->config->store();

    eval { Class::Load::load_class( $store_class ); 1 }
        or throw_fatal "Unable to load store class $store_class: $@";

    return $store_class->new( config => $self->config(),
                              logger => $self->logger() );
}

#-------------------------------------------------------------------------------

sub _build_cache {
    my ($self) = @_;

    return Pinto::IndexCache->new( config => $self->config(),
                                   logger => $self->logger() );
}

#-------------------------------------------------------------------------------
# Methods

sub add_distribution {
    my ($self, $struct) = @_;

    my $dist = $self->db->new_distribution($struct);

    $self->db->insert_distribution($dist);

    $self->store->add_archive( $dist->archive( $self->root_dir() ) );

    return $dist;
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, $dist) = @_;

    $self->db->delete_distribution($dist);

    $self->store->remove_archive( $dist->archive( $self->root_dir() ) );

    return $dist;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
