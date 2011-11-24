package Pinto::Repository;

# ABSTRACT: Coordinates the database, files, and indexes

use Moose;

use Class::Load;
use Path::Class;

use Pinto::Database;
use Pinto::IndexCache;
use Pinto::Extractor::Provides;
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


has extractor => (
    is         => 'ro',
    isa        => 'Pinto::Extractor::Provides',
    handles    => { provides => 'extract' },
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

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable
         Pinto::Role::UserAgent );

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

sub _build_extractor {
    my ($self) = @_;

    return Pinto::Extractor::Provides->new( config => $self->config(),
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
    my $path       = $author_dir->file($basename)->as_foreign('Unix');

    my $existing = $self->db->get_distribution_with_path($path);
    throw_error "Distribution $path already exists" if $existing;

    my @package_specs = $self->provides(archive => $archive);
    $self->whine("$archive contains no packages") if not @package_specs;

    for my $pkg (@package_specs) {
        my $where = { name => $pkg->{name}, 'distribution.source' => 'LOCAL'};
        my $incumbent = $self->db->get_all_packages($where)->first() or next;
        if ( (my $author = $incumbent->author() ) ne $author ) {
            throw_error "Only author $author can update package $pkg->{name}";
        }
    }

    my $count = @package_specs;
    $self->info("Adding distribution $path providing $count packages");

    my $dist = $self->db->new_distribution(path => $path);
    my @packages = map { $self->db->new_package(%{$_}) } @package_specs;

    $dist = $self->db->add_distribution_with_packages($dist, @packages);

    $self->store->add_archive( $archive => $dist->archive($root_dir) );

    return $dist;
}

#-------------------------------------------------------------------------------

sub import_distribution {
    my ($self, %args) = @_;


    my $url  = $args{url};
    my $path = $url->path(); # '/yadda/yadda/authors/id/A/AU/AUTHOR/Foo-1.2.tar.gz'
    $path    =~ s{^ .* /authors/id/(.*) $}{$1}mx;   # 'A/AU/AUTHOR/Foo-1.2.tar.gz'

    my $existing = $self->db->get_distribution_with_path($path);
    throw_error "Distribution $path already exists" if $existing;

    my @path_parts = split m{ / }mx, $path; # qw( A AU AUTHOR Foo-1.2.tar.gz )
    my $archive = file($self->config->root_dir(), qw(authors id), @path_parts);
    my $author  = $path_parts[2];

    $self->fetch( url => $url, to => $archive );

    my @package_specs = $self->provides(archive => $archive);
    $self->whine("$archive contains no packages") if not @package_specs;

    my $count = @package_specs;
    $self->info("Importing distribution $url providing $count packages");

    my $dist = $self->db->new_distribution(path => $path);
    my @packages = map { $self->db->new_package(%{$_}) } @package_specs;

    $dist = $self->db->add_distribution_with_packages($dist, @packages);

    $self->store->add_archive( $archive );

    return $dist;
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, %args) = @_;

    my $path = $args{path};

    my $dist = $self->db->get_distribution_with_path($path)
        or throw_error "Distribution $path does not exist";

    my $count = $dist->package_count();
    $self->info("Removing distribution $dist with $count packages");

    $self->db->remove_distribution($dist);

    my $archive = $dist->archive( $self->config->root_dir() );
    $self->store->remove_archive($archive);

    return $dist;
}

#-------------------------------------------------------------------------------

sub locate_remotely {
    my ($self, $package, $version) = @_;

    $self->debug("Searching for $package-$version");
    my $found = $self->cache->locate( $package => $version );

    return $found ? $found : ();
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
