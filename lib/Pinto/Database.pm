package Pinto::Database;

# ABSTRACT: Interface to the Pinto database

use Moose;

use version;
use Path::Class;
use Pinto::Schema;

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

    return Pinto::Schema->connect($dsn);
}

#-------------------------------------------------------------------------------
# Convenience methods

sub get_packages {
    my ($self, $package) = @_;

    my $attrs = { prefetch => 'distribution' };
    my $where = { name => $package };

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub get_latest_package {
    my ($self, $package) = @_;

    my $where = { name => $package };
    my $attrs = { rows => 1, order_by => { -desc => [ qw(is_local version_numeric) ] }};

    return $self->schema->resultset('Package')->find($where, $attrs);
}

#-------------------------------------------------------------------------------

sub get_distribution {
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

    my $latest = $self->get_latest_package($pkg->{name});
    if ($latest and $pkg->{version_numeric} > $latest->version_numeric()) {
        $pkg->{should_index} = 1;
        $latest->should_index(0);
        $latest->update();
    }
    elsif ($latest and $pkg->{is_local} and $pkg->{version_numeric} == $latest->version_numeric()) {
        $pkg->{should_index} = 1;
        $latest->should_index(0);
        $latest->update();
    }
    elsif (not defined $latest) {
        $pkg->{should_index} = 1;
    }

    return $self->schema->resultset('Package')->create( $pkg );
}

#-------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, $dist) = @_;

    $self->logger->info(sprintf "Removing $dist with %i packages", $dist->package_count());
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
    $self->get_latest_package($name)->update( {should_index => 1} ) if $was_indexed;

    return;
}

#-------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $details = CPAN::PackageDetails->new();
    my $indexed_rs = $self->schema->resultset('Package')->indexed();

    while ( my $pkg = $indexed_rs->next() ) {
        $details->add_entry(
            package_name => $pkg->name(),
            version      => $pkg->version(),
            path         => $pkg->distribution->path(),
        );
    }

    my $index_file = $self->config->packages_details_file();
    $details->write_file($index_file);
}

#-------------------------------------------------------------------------------

sub load_index {
    my ($self, $index_file) = @_;

    $self->logger->info("Loading index from $index_file");
    my $details = CPAN::PackageDetails->read( "$index_file" );
    my ($records) = $details->entries->as_unique_sorted_list();

    my %dists;
    $dists{$_->path()}->{$_->package_name()} = $_->version() for @{$records};


    my @first_100 = (sort keys %dists)[1..100];
    foreach my $path ( @first_100 ) {

      next if $self->schema->resultset('Distribution')->find( {path => $path} );
      my $dist = $self->add_distribution( {path => $path, origin => $source} );

      foreach my $package (keys %{ $dists{$path} } ) {
        my $version = $dists{$path}->{$package};
        my $version_numeric = version->parse($version)->numify();
        $self->add_package( { name            => $package,
                              version         => $version,
                              version_numeric => $version_numeric,
                              distribution    => $dist->id() } );
      }
    }
}

#-------------------------------------------------------------------------------

sub all_packages {
    my ($self) = @_;

    return $self->schema->resultset('Package')->every();
}

#-------------------------------------------------------------------------------

sub local_packages {
    my ($self) = @_;

    return $self->schema->resultset('Package')->locals();
}

#------------------------------------------------------------------------------

sub foreign_packages {
    my ($self) = @_;

    return $self->schema->resultset('Package')->foreigners();
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

    $DB::single = 1;
    $self->mkpath( $self->config->db_dir() );
    $self->schema->deploy();

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
