package Pinto::Database;

# ABSTRACT: Interface to the Pinto database

use Moose;

use Try::Tiny;
use Path::Class;

use Pinto::Schema;
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

sub select_distributions {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    return $self->schema->resultset('Distribution')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_packages {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub new_distribution {
    my ($self, $dist_attrs) = @_;

    return $self->schema->resultset('Distribution')->new_result($dist_attrs);
}

#-------------------------------------------------------------------------------

sub insert_distribution {
    my ($self, $dist) = @_;

    $self->debug("Inserting distribution $dist into database");

    $self->warning("Developer distribution $dist will not be indexed")
        if $dist->is_devel() and not $self->config->devel();

    my $txn_guard = $self->schema->txn_scope_guard(); # BEGIN transaction

    $dist->insert();
    $self->mark_latest($_) for $dist->packages();

    $txn_guard->commit(); #END transaction

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_distribution {
    my ($self, $dist) = @_;

    $self->debug("Deleting distribution $dist from database");

    my $txn_guard = $self->schema->txn_scope_guard(); # BEGIN transaction

    # NOTE: must fetch the packages before we delete the dist,
    # otherwise they won't be there any more!
    my @packages = $dist->packages();

    $dist->delete();
    $self->mark_latest($_) for @packages;

    $txn_guard->commit(); # END transaction

    return $self;
}

#-------------------------------------------------------------------------------

sub mark_latest {
    my ($self, $pkg) = @_;

    my @sisters = $self->select_packages( {name => $pkg->name()} )->all();
    @sisters = grep { not $_->distribution->is_devel() } @sisters unless $self->config->devel();
    return if not @sisters;

    my ($latest, @older) = reverse sort { $a <=> $b } @sisters;

    # If the latest package is already marked as latest, then we can bail
    return $self if $latest->is_latest();

    # Mark older packages as 'undef' first, to prevent constraint violation.
    # The schema only permits one package to be marked as latest at a time.
    $_->is_latest(undef) for @older;
    $_->update() for @older;

    $self->debug("Marking package $latest as latest");
    $latest->is_latest(1);
    $latest->update();

    return $latest;
}

#-------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $writer = Pinto::IndexWriter->new( logger => $self->logger(),
                                          db     => $self );

    my $index_file = $self->config->index_file();
    $writer->write(file => $index_file);

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
