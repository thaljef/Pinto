package Pinto::Repository;

# ABSTRACT: Coordinates the database, files, and indexes

use Moose;

use Try::Tiny;
use Class::Load;

use Pinto::Database;
use Pinto::IndexCache;
use Pinto::Types qw(Dir);
use Pinto::Exceptions qw(throw_fatal throw_error);

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


has extractor => (
    is         => 'ro',
    isa        => 'Pinto::PackageExtractor',
    lazy_build => 1,
);


#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable
         Pinto::Role::FileFetcher );

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

    try   { Class::Load::load_class( $store_class ) }
    catch { throw_fatal "Unable to load store class $store_class: $_" };

    return $store_class->new( config => $self->config(),
                              logger => $self->logger() );
}

#-------------------------------------------------------------------------------

sub _build_cache {
    my ($self) = @_;

    return Pinto::IndexCache->new( config => $self->config(),
                                   logger => $self->logger() );
}

#------------------------------------------------------------------------------

sub _build_extractor {
    my ($self) = @_;

    return Pinto::PackageExtractor->new( config => $self->config(),
                                         logger => $self->logger() );
}


#-------------------------------------------------------------------------------
# Methods

sub add_archive {
    my ($self, %args) = @_;

    my $path   = $args{path};
    my $author = $args{author};
    my $index  = $args{index};
    my $stack  = $args{stack};
    my $pin    = $args{pin};

    throw_error "Archive $path does not exist"  if not -e $path;
    throw_error "Archive $path is not readable" if not -r $path;

    $stack = $self->db->select_stacks( {name => $stack} )->single()
        || throw_error qq{No such stack named "$stack"};

    $pin = $self->db->create_pin( {reason => $pin} )
        if $pin;

    my $basename   = $path->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path  = $author_dir->file($basename)->as_foreign('Unix')->stringify();

    $self->select_distributions( {path => $dist_path} )->single()
        and throw_error "Distribution $dist_path already exists";

    my $dist_struct = { path     => $dist_path,
                        source   => 'LOCAL',
                        mtime    => Pinto::Util::mtime($path) };

    my @pkg_specs = $index ? $self->extractor->provides( archive => $path ) : ();
    $dist_struct->{packages} = \@pkg_specs;

    my $count = @pkg_specs;
    $self->info("Adding distribution $path with $count packages");

    # Always update database *before* moving the archive into the
    # repository, so if there is an error in the DB, we can stop and
    # the repository will still be clean.

    my $new_dist    = $self->db->create_distribution( $dist_struct, $stack, $pin );
    my $new_archive = $new_dist->archive( $self->root_dir() );
    $self->fetch( from => $path, to => $new_archive );
    $self->store->add_archive( $new_archive );

    return $new_dist;
}

#-------------------------------------------------------------------------------

sub remove_archive {
    my ($self, %args) = @_;

    my $path = $args{path};

    my $where = {path => $path};
    my $attrs = {prefetch => 'packages'};
    my $dist  = $self->select_distributions($where, $attrs)->single();
    throw_error "Distribution $path does not exist" if not $dist;

    $count = $dist->package_count();
    $self->info("Removing distribution $dist with $count packages");

    $self->db->delete_distribution($dist);

    $self->store->remove_archive( $dist->archive( $self->root_dir() ) );

    return $dist;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
