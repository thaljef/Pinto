package Pinto::IndexManager;

# ABSTRACT: Manages the indexes of a Pinto repository

use Moose;
use Moose::Autobox;

use Path::Class;
use File::Compare;

use Dist::Metadata 0.920; # supports .zip

use CPAN::PackageDetails;

use Pinto::Util;
use Pinto::Index;

use Pinto::Exception::Args qw(throw_args);
use Pinto::Exception::IO qw(throw_io);
use Pinto::Exception::Unauthorized;
use Pinto::Exception::DuplicateDist;
use Pinto::Exception::IllegalDist;

use Pinto::Schema;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Attributes

has schema => (
    is          => 'ro',
    isa         => 'DBIx::Class::Schema',
    init_arg    => undef,
    lazy_build  => 1,
);

#-----------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable
         Pinto::Role::UserAgent );

#------------------------------------------------------------------------------

sub _build_schema {
  my ($self) = @_;

  my $db_file = $self->config->db_file();

  return Pinto::Schema->connect("dbi:SQLite:dbname=$db_file");

}

#------------------------------------------------------------------------------

sub create_db {
  my ($self) = @_;

  $self->mkpath( $self->config->db_dir() );
  $self->schema->deploy();

  return 1;
}

#------------------------------------------------------------------------------

sub load_foreign_index {
    my ($self, %args) = @_;

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


    $DB::single = 1;
    foreach my $location ( sort keys %dists ) {

      next if $self->schema->resultset('Distribution')->find( {location => $location} );
      $self->logger->info("Loading index data for $location");
      my $dist = $self->schema->resultset('Distribution')->create(
          { location => $location,
            origin   => $source,
          }
      );

      foreach my $package (keys %{ $dists{$location} } ) {
        my $pkg = $self->schema->resultset('Package')->create(
          { name         => $package,
            version      => $dists{$location}->{$package},
            distribution => $dist->id(),
          }
        );
      }
    }
}

#------------------------------------------------------------------------------

sub all_packages {
    my ($self) = @_;

    return $self->schema->resultset('Package')->all();
}


#------------------------------------------------------------------------------

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

sub foreign_distributions {
    my ($self) = @_;

    return $self->schema->resultset('Distribution')->foreigners();
}

#------------------------------------------------------------------------------

sub blocked_packages {
    my ($self) = @_;

    return $self->schema->resultset('Package')->blocked();
}

#------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $details = CPAN::PackageDetails->new();
    my $index_pkg_rs = $self->schema->resultset('Package')->indexed();
    while ( my $pkg = $index_pkg_rs->next() ) {
        $details->add_entry(
            package_name => $pkg->name(),
            version      => $pkg->version(),
            path         => $pkg->distribution->location(),
        );
    }

    my $details_file = $self->config->modules_dir->file('02packages.details.txt.gz');
    $details->write_file($details_file);
}

#------------------------------------------------------------------------------

sub remove_distribution {
    my ($self, %args) = @_;

    my $where = {location => $args{location} };
    my $dist  = $self->schema->resultset('Distribution')->find( $where );
    return if not $dist;

    $self->logger->info(sprintf "Removing $dist with %i packages", $dist->package_count());
    $dist->delete();

    return $dist;
}

#------------------------------------------------------------------------------

sub add_local_distribution {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $author = $args{author};

    my $basename   = $file->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $location   = $author_dir->file($basename)->as_foreign('Unix');

    my @packages = $self->_extract_packages(file => $file) ;
    $self->logger->info(sprintf "Adding $location with %i packages", scalar @packages);

    # Create new dist
    my $dist = $self->schema->resultset('Distribution')->create(
        { location => $location, origin => 'LOCAL'} );


    for my $pkg ( $self->_extract_packages(file => $file) ) {

      # Delete old local package
      my $attrs = { join => 'distribution'};
      my $where = { name => $pkg->{name}, 'distribution.origin' => 'LOCAL'};
      my $rs = $self->schema->resultset('Package')->search($where, $attrs);
      $rs->delete_all() if $rs;

      # Create new local package
      $self->schema->resultset('Package')->create(
          { %{ $pkg }, distribution => $dist->id() } );

    }

    return $dist;
}

#------------------------------------------------------------------------------

sub _extract_packages {
    my ($self, %args) = @_;

    my $file = $args{file};

    my $distmeta = Dist::Metadata->new(file => $file->stringify());
    my $provides = $distmeta->package_versions();
    throw_io "$file contains no packages" if not %{ $provides };

    my @packages = ();
    for my $package_name (sort keys %{ $provides }) {
        my $version = $provides->{$package_name} || 'undef';
        push @packages, { name => $package_name, version => $version };
    }

    return @packages;
}

#------------------------------------------------------------------------------

sub _distribution_check {
    my ($self, %args) = @_;
    my $file   = $args{file};
    my $author = $args{author};

    my $basename   = $file->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $location   = $author_dir->file($basename)->as_foreign('Unix');

    $self->schema->resultset('Distribution')->find( {location => $location} )
      && Pinto::Exception::DuplicateDist->throw("$location is already indexed");

    # TODO: return 1 if not indexed
    #       return 0 if indexed, but not on disk
    #       throw    if indexed, and same file exists on disk
    #       throw    if indexed, and different file exists on disk
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

The role of L<Pinto::IndexManager> and L<Pinto::Index> is to create an
abstraction layer between the rest of the application and the details
of managing the 02packages index file.  At the moment, we use three
separate index files: one for locally added packages, one for mirrored
packages, and a master index that combines the other two according to
specific rules.  But this file-based design is ugly and doesn't
perform well.  So in the future, I hope to replace those files with a
proper database.

=cut

