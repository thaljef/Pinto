package Pinto::Database;

# ABSTRACT: Interface to the Pinto database

use Moose;

use version;
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
         Pinto::Role::PathMaker );

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

    my $where = { name => $package, is_latest => 1 };

    # TODO: assert we only get one record here
    return $self->schema->resultset('Package')->first($where);
}

#-------------------------------------------------------------------------------

sub get_distribution {
    my ($self, $path) = @_;

    my $attrs = { prefetch => 'packages' };
    my $where = { path => $path };

    # TODO: assert we only get one record here!
    return $self->schema->resultset('Distribution')->search( $where, $attrs )->first();
}

#-------------------------------------------------------------------------------

sub add_dist {
    my ($self, $dist) = @_;

    return $self->schema->resultset('Distribution')->create( $dist );
}

#-------------------------------------------------------------------------------

sub add_package {
    my ($self, $pkg) = @_;

    my $latest = $self->get_latest_package($pkg->{name});
    if ($latest and $pkg->{version_numeric} > $latest->version_numeric()) {
        $pkg->{is_latest} = 1;
        $latest->is_latest(undef);
        $latest->update();
    }
    elsif (not defined $latest) {
        $pkg->{is_latest} = 1;
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

    my $name       = $pkg->name();
    my $was_latest = $pkg->is_latest();

    $pkg->delete();

    my $package_rs     = $self->get_packages($name);
    my $subquery_where = { name  => { '=' => \'me.name'  } };
    my $subquery_attrs = { alias => 'me2' };

    my $subquery = $package_rs->search($subquery_where, $subquery_attrs)
        ->get_column('version_numeric')->max_rs->as_query();

    if (my $latest = $package_rs->single( { version_numeric => { '=' => $subquery } } )) {
        $latest->is_latest(1);
        $latest->update();
    }

    return;
}

#-------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $details = CPAN::PackageDetails->new();
    my $latest_rs = $self->schema->resultset('Package')->latest();

    while ( my $pkg = $latest_rs->next() ) {
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

    # TODO: support "force";

    my $source = $self->config->source();
    my $temp_dir = File::Temp->newdir();
    my $index_url = URI->new("$source/modules/02packages.details.txt.gz");
    my $index_temp_file = file($temp_dir, '02packages.details.txt.gz');
    $self->fetch(url => $index_url, to => $index_temp_file);

    $self->logger->info("Loading foreign index file from $index_url");
    my $details = CPAN::PackageDetails->read( "$index_temp_file" );
    my ($records) = $details->entries->as_unique_sorted_list();

    my %dists;
    $dists{$_->path()}->{$_->package_name()} = $_->version() for @{$records};


    foreach my $path ( sort keys %dists ) {

      next if $self->schema->resultset('Distribution')->find( {path => $path} );
      $self->logger->debug("Loading index data for $path");
      my $dist = $self->schema->resultset('Distribution')->create(
          { path => $path,
            origin   => $source,
          }
      );

      foreach my $package (keys %{ $dists{$path} } ) {
        my $version = $dists{$path}->{$package};
        my $version_numeric = version->parse($version)->numify();
        my $pkg = $self->schema->resultset('Package')->create(
          { name            => $package,
            version         => $version,
            version_numeric => $version_numeric,
            distribution    => $dist->id(),
          }
        );
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
