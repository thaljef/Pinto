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

sub insert_distribution {
    my ($self, $dist_spec) = @_;

    $self->debug("Inserting distribution $dist_spec into database");

    my $txn_guard = $self->schema->txn_scope_guard();
    my $dist = $self->schema->resultset('Distribution')->create( $dist_spec->as_hashref() );
    $self->_mark_latest_package_with_name($_->name()) for $dist->packages();
    $txn_guard->commit();

    return $dist;
}

#-------------------------------------------------------------------------------

sub delete_distribution {
    my ($self, $dist) = @_;

    $self->debug("Deleting distribution $dist from database");

    my $txn_guard = $self->schema->txn_scope_guard();
    my @packages = $dist->packages();
    $dist->delete();
    $self->_mark_latest_package_with_name($_->name()) for @packages;
    $txn_guard->commit();

    return 1;
}


# sub delete_distribution {
#     my ($self, $dist) = @_;

#     $self->debug("Deleting distribution $dist from database");

#     my $txn_guard = $self->schema->txn_scope_guard();

#     $self->delete_package($_) for $dist->packages();
#     $dist->delete();

#     $txn_guard->commit();

#     return;
# }


#-------------------------------------------------------------------------------

sub _mark_latest_package_with_name {
    my ($self, $pkg_name) = @_;

    my @sisters  = $self->select_packages( {name => $pkg_name} )->all();
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
