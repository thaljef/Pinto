package Pinto::Database;

# ABSTRACT: Interface to the Pinto database

use Moose;

use Try::Tiny;
use Path::Class;

use Pinto::Schema;
use Pinto::IndexLoader;
use Pinto::IndexWriter;
use Pinto::Exceptions qw(throw_fatal);

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
    my ($self, $where) = @_;

    my $attrs = { prefetch => 'distribution' };

    return $self->schema->resultset('Package')->search($where || {}, $attrs);
}

#-------------------------------------------------------------------------------

sub get_all_indexed_packages {
    my ($self) = @_;

    my $where  = { should_index => 1 };
    my $select = [ qw(name version distribution.path) ];
    my $attrs  = { select => $select, join => 'distribution', order_by => 'name' };

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub get_packages_with_name {
    my ($self, $package_name, $attrs) = @_;

    my $where = { name => $package_name };
    $attrs ||= { prefetch => 'distribution' };

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub get_distribution_with_path {
    my ($self, $path, $attrs) = @_;

    my $where = { path => $path };
    $attrs ||= {};

    return $self->schema->resultset('Distribution')->search($where, $attrs)->single();
}

#-------------------------------------------------------------------------------

sub add_distribution {
    my ($self, $attrs) = @_;

    $self->debug("Loading distribution $attrs->{path}");

    my $dist = $self->schema->resultset('Distribution')->create($attrs);

    $self->whine("Developer distribution $dist will not be indexed") if $dist->is_devel();

    return $dist;
}

#-------------------------------------------------------------------------------

sub add_package {
    my ($self, $attrs) = @_;

    $self->debug("Loading package $attrs->{name}");

    my $pkg = $self->schema->resultset('Package')->create($attrs);

    if ( $pkg->is_devel() && !$pkg->distribution->is_devel() ) {
        my $vname = $pkg->name() . '-' . $pkg->version();
        $self->whine("Developer package $vname will not be indexed");
    }

    $self->mark_latest_package_for_indexing( $pkg->name() );

    return $pkg;
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, $dist) = @_;

    $self->info(sprintf "Removing distribution $dist with %i packages", $dist->package_count());
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
    $self->mark_latest_package_for_indexing($name) if $was_indexed;

    return;
}

#-------------------------------------------------------------------------------

sub mark_latest_package_for_indexing {
    my ($self, $pkg_name) = @_;

    my $sister_package_rs = $self->get_packages_with_name( $pkg_name );
    my @non_devel_sisters = grep { not $_->is_devel() } $sister_package_rs->all();
    return if not @non_devel_sisters;

    my ($newest, @older) = reverse sort {$a <=> $b} @non_devel_sisters;

    do { $_->should_index(0);      $_->update() } foreach @older;
    $newest->should_index(1); $newest->update();

    return $newest;
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

sub get_all_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->search();
}

#-------------------------------------------------------------------------------

sub get_all_outdated_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->outdated();
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
