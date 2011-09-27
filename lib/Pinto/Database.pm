package Pinto::Database;

# ABSTRACT: Interface to the Pinto database

use Moose;

use Try::Tiny;
use Path::Class;
use List::Util qw(first);

use Pinto::Schema;
use Pinto::IndexLoader;
use Pinto::IndexWriter;
use Pinto::Exceptions qw(throw_fatal throw_error);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has schema => (
   is         => 'ro',
   isa        => 'Pinto::Schema',
   init_arg   => undef,
   lazy_build => 1,
);

#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable
         Pinto::Role::PathMaker
         Pinto::Role::UserAgent );

#-------------------------------------------------------------------------------
# Builders

sub _build_schema {
    my ($self) = @_;
    my $db_file = $self->config->db_file();
    my $dsn = "dbi:SQLite:$db_file";

    my $connection;
    try   { $connection = Pinto::Schema->connect($dsn) }
    catch { throw_fatal "Database error: $_" };

    return $connection;
}

#-------------------------------------------------------------------------------
# Convenience methods

sub get_all_packages {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= { prefetch => 'distribution' };

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------
# TODO: Move this into IndexWriter

sub get_records_for_packages_details {
    my ($self) = @_;

    my $where  = { is_latest => 1 };
    my $select = [ qw(name version distribution.path) ];
    my $attrs  = { select => $select, join => 'distribution'};

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub get_all_packages_with_name {
    my ($self, $package_name) = @_;

    my $where = { name => $package_name };

    return $self->schema->resultset('Package')->search($where);
}

#-------------------------------------------------------------------------------

sub get_distribution_with_path {
    my ($self, $path) = @_;

    my $where = { path => $path };

    return $self->schema->resultset('Distribution')->search($where)->single();
}

#-------------------------------------------------------------------------------

sub new_distribution {
    my ($self, %attributes) = @_;

    return $self->schema->resultset('Distribution')->new_result(\%attributes);

}

#-------------------------------------------------------------------------------

sub add_distribution {
    my ($self, $dist) = @_;

    $self->debug("Loading distribution $dist");

    $self->whine("Developer distribution $dist will not be indexed") if $dist->is_devel();

    return $dist->insert();
}

#-------------------------------------------------------------------------------

sub new_package {
    my ($self, %attributes) = @_;

    return $self->schema->resultset('Package')->new_result(\%attributes);
}

#-------------------------------------------------------------------------------

sub add_package {
    my ($self, $pkg) = @_;

    $self->debug("Loading package $pkg");

    # Pinto::Package actally computes the numeric version on the fly
    # when you call the version_numeric() method, and forces it to
    # 0.00 then.  But we only want to warn about it when first loading
    # the package. Ignore this warning at your own peril.

    try   { Pinto::Util::numify_version( $pkg->version() ) if not $pkg->is_devel() }
    catch { $self->whine("$pkg: Illegal version will be forced to 0") };

    # Remember: All packages in a devel dist are considered devel,
    # but a non-devel dist may contain devel packages.  Not sure
    # if that's how PAUSE really does it though.

    # Don't whine about a devel package if it was in a devel dist,
    # since we already whined about that when we added the dist.

    $self->whine("Developer package $pkg will not be indexed")
        if $pkg->is_devel() && !$pkg->distribution->is_devel();

    # Devel packages can have any version at all.  But non-devel
    # packages must always have an increasing version number.
    # TODO: consider removing exemption for devel packages.
    $self->check_for_regressive_version($pkg) if not $pkg->is_devel();

    # Must insert *before* attempting to mark the latest package
    $pkg->insert();

    # Devel packages are never marked as latest, so assume
    # that the latest package hasn't changed.
    $self->mark_latest_package_with_name( $pkg->name() ) if not $pkg->is_devel();

    return $pkg;
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, $dist) = @_;

    # TODO: check that dist exists

    $self->info(sprintf "Removing distribution $dist with %i packages", $dist->package_count());
    $self->remove_package($_) for $dist->packages();
    $dist->delete();

    return;
}

#-------------------------------------------------------------------------------

sub remove_package {
    my ($self, $pkg) = @_;

    my $name       = $pkg->name();
    my $was_latest = $pkg->is_latest();

    $pkg->delete();
    $self->mark_latest_package_with_name($name) if $was_latest;

    return;
}

#-------------------------------------------------------------------------------

sub mark_latest_package_with_name {
    my ($self, $pkg_name) = @_;

    my @sisters = $self->get_all_packages_with_name( $pkg_name )->all();
    my @non_devel_sisters = grep { not $_->is_devel() } @sisters;
    return if not @non_devel_sisters;

    my ($latest, @older) = reverse sort {$a <=> $b} @non_devel_sisters;

    do { $_->is_latest(undef); $_->update() } for @older;

    $self->debug("Marking $latest as the latest version");
    $latest->is_latest(1);

    return $latest->update();
}

#-------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $writer = Pinto::IndexWriter->new( logger => $self->logger(),
                                          db     => $self );

    my $index_file = $self->config->packages_details_file();
    $writer->write(file => $index_file);

    return $self;
}

#-------------------------------------------------------------------------------

sub load_index {
    my ($self, $repos_url) = @_;

    my $loader = Pinto::IndexLoader->new( logger => $self->logger(),
                                          db     => $self );

    $loader->load(from => $repos_url);

    return $self;
}

#------------------------------------------------------------------------------

sub get_all_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->search();
}

#-------------------------------------------------------------------------------

sub get_all_local_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->locals();
}

#------------------------------------------------------------------------------

sub get_all_foreign_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->foreigners();
}

#------------------------------------------------------------------------------

sub get_all_outdated_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->outdated();
}

#-------------------------------------------------------------------------------

sub check_for_regressive_version {
    my ($self, $pkg) = @_;

    # Foreign packages always sort before local ones, so we don't need
    # to worry about comparing those with each other.  But we must
    # compare a local package with any other local packages of the
    # same name.  Likewise, we must compare a foreign package with any
    # other foreign packages of the same name.

    my $sisters = $self->get_all_packages_with_name( $pkg->name() );
    my @sisters = grep { $_->is_local() eq $pkg->is_local() } $sisters->all();

    if ( my $higher_pkg = first {$_ > $pkg} @sisters ) {
        my $higher_dist = $higher_pkg->distribution();
        throw_error "New package $pkg has lower version " .
            "than existing package $higher_pkg in $higher_dist";
    }

    return $self;
}

#-------------------------------------------------------------------------------

sub deploy {
    my ($self) = @_;

    $self->mkpath( $self->config->db_dir() );
    $self->debug( 'Creating database at ' . $self->config->db_file() );
    $self->schema->deploy();

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
