package Pinto::Repository;

# ABSTRACT: Coordinates the database, files, and indexes

use Moose;

use Class::Load;
use Path::Class;

use Pinto::Database;
use Pinto::IndexCache;
use Pinto::PackageExtractor;
use Pinto::DistributionSpec;
use Pinto::Exceptions qw(throw_fatal throw_error);
use Pinto::Types qw(Dir);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has db => (
    is         => 'ro',
    isa        => 'Pinto::Database',
    handles    => [ qw(write_index) ],
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


has package_extractor => (
    is         => 'ro',
    isa        => 'Pinto::PackageExtractor',
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

sub _build_package_extractor {
    my ($self) = @_;

    return Pinto::PackageExtractor->new( config => $self->config(),
                                         logger => $self->logger() );
}

#-------------------------------------------------------------------------------
# Methods

sub add_distribution {
    my ($self, %args) = @_;

    my $archive = $args{archive};
    my $author  = $args{author};

    throw_error "Archive $archive does not exist"  if not -e $archive;
    throw_error "Archive $archive is not readable" if not -r $archive;

    my $root_dir   = $self->config->root_dir();
    my $basename   = $archive->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $path       = $author_dir->file($basename)->as_foreign('Unix')->stringify();

    my $where    = {path => $path};
    my $existing = $self->db->select_distributions( $where )->single();
    throw_error "Distribution $path already exists" if $existing;

    my @package_specs = $self->package_extractor->provides(archive => $archive);
    $self->whine("$archive contains no packages") if not @package_specs;

    for my $pkg (@package_specs) {
        my $attrs = { prefetch => 'distribution' };
        my $where = { name => $pkg->{name}, 'distribution.source' => 'LOCAL'};
        my $incumbent = $self->db->select_packages($where, $attrs)->first() or next;
        if ( (my $incumbent_author = $incumbent->author()) ne $author ) {
            throw_error "Only author $incumbent_author can update package $pkg->{name}";
        }
    }

    my $count = @package_specs;
    $self->info("Adding distribution $path providing $count packages");

    my $dist_spec = Pinto::DistributionSpec->new( path     => $path,
                                                  source   => 'LOCAL',
                                                  packages => \@package_specs );

    my $dist = $self->db->insert_distribution($dist_spec);
    $self->store->add_archive( $archive => $dist->archive($root_dir) );

    return $dist;
}

#-------------------------------------------------------------------------------

sub import_distribution {
    my ($self, %args) = @_;

    my $url  = $args{url};
    my ($source, $path, $author, $archive) =
      Pinto::Util::parse_dist_url( $url, $self->config->root_dir() );

    my $where    = {path => $path};
    my $existing = $self->db->select_distributions( $where )->single();
    throw_error "Distribution $path already exists" if $existing;

    $self->fetch( url => $url, to => $archive );

    my @package_specs = $self->package_extractor->provides(archive => $archive);
    $self->whine("$archive contains no packages") if not @package_specs;

    my $count = @package_specs;
    $self->info("Importing distribution $url providing $count packages");

    my $dist_spec = Pinto::DistributionSpec->new( path     => $path,
                                                  source   => $source,
                                                  packages => \@package_specs );

    my $dist = $self->db->insert_distribution( $dist_spec );
    $self->store->add_archive( $archive );

    return $dist;
}

#-------------------------------------------------------------------------------

sub mirror_distribution {
    my ($self, %args) = @_;

    my $url = $args{url};

    my @path_parts = split m{ / }mx, $url;
    my $destination = $self->repos->root_dir->file( qw(authors id), @path_parts );

    $self->fetch(url => $url, to => $destination);

    #my $dist = $self->repos->db->new_distribution( %{ $dist_spec } );
    #$self->repos->db->insert_distribution($dist, @{ $dist_spec->{packages} });
    #$self->repos->store->add_archive($destination);

    return 1;
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, %args) = @_;

    my $path = $args{path};

    my $where = {path => $path};
    my $dist  = $self->db->select_distributions( $where )->single()
        or throw_error "Distribution $path does not exist";

    my $count = $dist->package_count();
    $self->info("Removing distribution $dist with $count packages");

    $self->db->delete_distribution($dist);

    my $archive = $dist->archive( $self->config->root_dir() );
    $self->store->remove_archive($archive);

    return $dist;
}

#-------------------------------------------------------------------------------

sub locate_remotely {
    my ($self, @args) = @_;

    return $self->cache->locate( @args );
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
