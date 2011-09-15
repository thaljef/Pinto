package Pinto::IndexManager;

# ABSTRACT: Manages the indexes of a Pinto repository

use Moose;
use Moose::Autobox;

use Path::Class;
use File::Compare;

use Dist::Metadata 0.920; # supports .zip

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

sub update_mirror_index {
    my ($self, %args) = @_;

    my $repos  = $self->config->repos();
    my $source = $self->config->source();
    my $force  = $args{force};

    my $remote_url = URI->new("$source/modules/02packages.details.txt.gz");
    my $repos_file = file($repos, 'modules', '02packages.details.mirror.txt.gz');
    my $has_changed = $self->fetch(url => $remote_url, to => $repos_file);
    $self->logger->info("Index from $source is up to date") unless $has_changed or $force;
    $self->mirror_index->reload() if $has_changed or $force;

    return $has_changed;
}

#------------------------------------------------------------------------------

sub dists_to_mirror {
    my ($self) = @_;

    my $temp_index = Pinto::Index->new( logger => $self->logger() );
    $temp_index->add( $self->mirror_index->packages->values->flatten() );
    $temp_index->remove( $self->local_index->packages->values->flatten() );

    my $sorter = sub { $_[0]->location() cmp $_[1]->location() };

    return $temp_index->distributions->values->sort($sorter)->flatten();
}

#------------------------------------------------------------------------------

sub all_packages {
    my ($self) = @_;

    my $sorter = sub { $_[0]->name() cmp $_[1]->name() };

    return $self->master_index->packages->values->sort($sorter)->flatten();
}


#------------------------------------------------------------------------------

sub local_packages {
    my ($self) = @_;

    my $sorter = sub { $_[0]->name() cmp $_[1]->name() };

    return $self->local_index->packages->values->sort($sorter)->flatten();
}

#------------------------------------------------------------------------------

sub foreign_packages {
    my ($self) = @_;

    my $foreigners = [];
    for my $package ( $self->master_index->packages->values->flatten() ) {
        my $name = $package->name();
        $foreigners->push($package) if not $self->local_index->packages->at($name);
    }

    my $sorter = sub { $_[0]->name() cmp $_[1]->name() };
    return $foreigners->sort($sorter)->flatten();

}


#------------------------------------------------------------------------------

sub conflict_packages {
    my ($self) = @_;

    my $conflicts = [];
    for my $local_package ( $self->local_index->packages->values->flatten() ) {
        my $name = $local_package->name();
        $conflicts->push($local_package) if $self->mirror_index->packages->at($name);
    }

    my $sorter = sub { $_[0]->name() cmp $_[1]->name() };
    return $conflicts->sort($sorter)->flatten();
}

#------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    # TODO!

    return $self;
}

#------------------------------------------------------------------------------

sub add_mirrored_distribution {
    my ($self, %args) = @_;

    my $dist = $args{dist};

    # Don't add a distribution that already exists in the index.
    if ( $self->master_index->distributions->at($dist->location) ) {
        $self->logger->debug("$dist is already in the index");
        return;
    }

    my @packages = $dist->packages->flatten();
    my @removed_dists = $self->master_index->add( @packages );

    return @removed_dists;
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
      $rs->delete() if $rs;

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

