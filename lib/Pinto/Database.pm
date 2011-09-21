package Pinto::Database;

# ABSTRACT: Interface to the Pinto database

use Moose;

use Try::Tiny;
use Path::Class;

use Pinto::Schema;
use Pinto::IndexLoader;
use Pinto::IndexWriter;
use Pinto::Exceptions qw(throw_db);

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
    catch { throw_db "Database error: $_" };

    return $connection;
}

#-------------------------------------------------------------------------------
# Convenience methods

sub get_all_packages {
    my ($self, $where) = @_;

    my $attrs = { prefetch => 'distribution' };

    return $self->schema->resultset('Package')->search($where || {}, $attrs);
}

#-------------------------------------------------------------------------------

sub get_all_indexed_packages {
    my ($self) = @_;

    my $where = { should_index => 1 };
    my $attrs = { prefetch => 'distribution', order_by => 'name' };

    return $self->schema->resultset('Package')->search($where, $attrs);
}
#-------------------------------------------------------------------------------

sub get_packages_with_name {
    my ($self, $package_name) = @_;

    my $where = { name => $package_name };
    my $attrs = { prefetch => 'distribution' };

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub get_latest_package_with_name {
    my ($self, $package_name) = @_;

    my $where = { name => $package_name };
    my $attrs = { rows => 1, order_by => { -desc => [ qw(is_local version_numeric) ] }};

    return $self->schema->resultset('Package')->find($where, $attrs);
}

#-------------------------------------------------------------------------------

sub get_distribution_with_path {
    my ($self, $path) = @_;

    my $where = { path => $path };

    return $self->schema->resultset('Distribution')->single($where);
}

#-------------------------------------------------------------------------------

sub add_distribution {
    my ($self, $dist) = @_;

    return $self->schema->resultset('Distribution')->create($dist);
}

#-------------------------------------------------------------------------------

sub add_package {
    my ($self, $pkg) = @_;

    if ( my $latest = $self->get_latest_package_with_name( $pkg->{name} ) ) {

        if ( $pkg->{is_local} and not $latest->is_local() ) {
            $pkg->{should_index} = 1;
            $latest->should_index(0);
            $latest->update();
        }
        elsif ( $latest->is_local() and not $pkg->{is_local} ) {
            $pkg->{should_index} = 0;
        }
        elsif ( $pkg->{version_numeric} > $latest->version_numeric() ) {
            $pkg->{should_index} = 1;
            $latest->should_index(0);
            $latest->update();
        }
    }
    else {
        $pkg->{should_index} = 1;
    }

   return $self->schema->resultset('Package')->create($pkg);
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, $dist) = @_;

    $self->info(sprintf "Removing $dist with %i packages", $dist->package_count());
    $self->remove_package($_) for $dist->packages();
    $dist->delete();

    return;
}

#-------------------------------------------------------------------------------

sub remove_package {
    my ($self, $pkg) = @_;

    my $name        = $pkg->name();
    my $was_indexed = $pkg->should_index();

    $pkg->delete();

    if ($was_indexed) {
        my $next_latest = $self->get_latest_package_with_name($name) or return;
        $next_latest->update( {should_index => 1} );
    }

    return;
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

sub blocked_packages {
    my ($self) = @_;

    return $self->schema->resultset('Package')->blocked();
}

#------------------------------------------------------------------------------

sub blocking_packages {
    my ($self) = @_;

    return $self->schema->resultset('Package')->blocking();
}

#------------------------------------------------------------------------------

sub local_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->locals();
}

#------------------------------------------------------------------------------

sub foreign_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->foreigners();
}

#-------------------------------------------------------------------------------

sub deploy {
    my ($self) = @_;

    $self->mkpath( $self->config->db_dir() );
    $self->schema->deploy();

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
