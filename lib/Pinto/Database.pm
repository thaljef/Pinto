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

sub get_latest_package_with_name {
    my ($self, $package_name) = @_;

    my $where = { name => $package_name, is_latest => 1 };

    return $self->schema->resultset('Package')->search($where)->single();
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

sub add_distribution_with_packages {
    my ($self, $dist, @packages) = @_;

    $self->debug("Loading distribution $dist");

    $self->whine("Developer distribution $dist will not be indexed")
        if $dist->is_devel() and not $self->config->devel();

    my $txn_guard = $self->schema->txn_scope_guard();
    $dist->insert();

    for my $pkg ( @packages ) {
        $pkg->distribution($dist);
        $self->add_package($pkg)
    }

    $txn_guard->commit();

    return $dist;
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

    $pkg->insert();

    try   { $self->mark_latest_package_with_name( $pkg->name() ) }
    catch { throw_error "Unable to accept $pkg into the repository: $_" };

    return $pkg;
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, $dist) = @_;

    $self->info(sprintf "Removing distribution $dist with %i packages", $dist->package_count());

    my $txn_guard = $self->schema->txn_scope_guard();

    $self->remove_package($_) for $dist->packages();
    $dist->delete();

    $txn_guard->commit();

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

    my @sisters  = $self->get_all_packages_with_name( $pkg_name )->all();
    @sisters = grep { not $_->is_devel() } @sisters unless $self->config->devel();
    return $self if not @sisters;

    my ($latest, @older) = reverse sort { $a <=> $b } @sisters;

    # Mark older packages as 'undef' first, to prevent contraint violation.
    # The schema only allows one package to be marked latest at a time.

    $_->is_latest(undef) for @older;
    $_->update() for @older;

    $latest->is_latest(1);
    $latest->update();

    return $self;
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
