package Pinto::Database;

# ABSTRACT: Interface to the Pinto database

use Moose;

use Try::Tiny;
use Path::Class;

use Pinto::Schema;
use Pinto::IndexReader;
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

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable
         Pinto::Role::PathMaker );

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

sub get_distributions {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    return $self->schema->resultset('Distribution')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub get_packages {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub new_distribution {
    my ($self, %attributes) = @_;

    return $self->schema->resultset('Distribution')->new_result(\%attributes);

}

#-------------------------------------------------------------------------------

sub new_package {
    my ($self, %attributes) = @_;

    return $self->schema->resultset('Package')->new_result(\%attributes);
}

#-------------------------------------------------------------------------------

sub add_distribution {
    my ($self, $dist, @packages) = @_;

    $self->debug("Loading distribution $dist into database");

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

sub add_package {
    my ($self, $pkg) = @_;

    $self->debug("Loading package $pkg into database");

    $pkg->insert();

    $self->_mark_latest_package_with_name( $pkg->name() );

    return $pkg;
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, $dist) = @_;

    $self->debug("Removing distribution $dist from database");

    my $txn_guard = $self->schema->txn_scope_guard();

    $self->remove_package($_) for $dist->packages();
    $dist->delete();

    $txn_guard->commit();

    return;
}


#-------------------------------------------------------------------------------

sub remove_package {
    my ($self, $pkg) = @_;

    $self->debug("Removing package $pkg from database");

    my $name       = $pkg->name();
    my $was_latest = $pkg->is_latest();

    $pkg->delete();
    $self->_mark_latest_package_with_name($name) if $was_latest;

    return;
}

#-------------------------------------------------------------------------------

sub _mark_latest_package_with_name {
    my ($self, $pkg_name) = @_;

    my @sisters  = $self->get_packages( {name => $pkg_name} )->all();
    @sisters = grep { not $_->is_devel() } @sisters unless $self->config->devel();
    return $self if not @sisters;

    my ($latest, @older) = reverse sort { $a <=> $b } @sisters;

    # If the latest package is already marked as latest, then we can bail
    return $self if $latest->is_latest();

    # Mark older packages as 'undef' first, to prevent contraint violation.
    # The schema only allows one package to be marked latest at a time.
    $_->is_latest(undef) for @older;
    $_->update() for @older;

    $self->debug("Marking $latest as latest");
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

    my $reader = Pinto::IndexReader->new( logger => $self->logger(),
                                          source => $repos_url );

    my $loader = Pinto::IndexLoader->new( logger => $self->logger(),
                                          db     => $self );
    $loader->load(reader => $reader);

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
