package Pinto::IndexManager;

# ABSTRACT: Manages the indexes of a Pinto repository

use Moose;
use Moose::Autobox;

use DBI;
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

=attr mirror_index

Returns the L<Pinto::Index> that represents our copy of the
F<02packages> file from a CPAN mirror (or possibly another Pinto
repository).  This index will include the latest versions of all the
packages on the mirror.

=cut

has 'mirror_index' => (
    is             => 'ro',
    isa            => 'Pinto::Index',
    builder        => '__build_mirror_index',
    init_arg       => undef,
    lazy           => 1,
);

=attr local_index

Returns the L<Pinto::Index> that represents the F<02packages> file for
your local packages.  This index will include only those packages that
you've locally added to the repository.

=cut

has 'local_index'   => (
    is              => 'ro',
    isa             => 'Pinto::Index',
    builder         => '__build_local_index',
    init_arg        => undef,
    lazy            => 1,
);

=attr master_index

Returns the L<Pinto::Index> that is the logical combination of
packages from both the mirror and local indexes.

=cut

has 'master_index'  => (
    is              => 'ro',
    isa             => 'Pinto::Index',
    builder         => '__build_master_index',
    init_arg        => undef,
    lazy            => 1,
);

has schema => (
    is          => 'ro',
    isa         => 'DBIx::Class::Schema',
    init_arg    => undef,
    lazy_build  => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable
         Pinto::Role::UserAgent );

#------------------------------------------------------------------------------
# Builders

sub __build_mirror_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.mirror.txt.gz');
}

#------------------------------------------------------------------------------

sub __build_local_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.local.txt.gz');
}

#------------------------------------------------------------------------------

sub __build_master_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.txt.gz');
}

#------------------------------------------------------------------------------

sub __build_index {
    my ($self, %args) = @_;

    my $repos = $self->config->repos();
    my $index_file = Path::Class::file($repos, 'modules', $args{file});

    return Pinto::Index->new( noclobber => $self->config->noclobber(),
                              logger    => $self->logger(),
                              file      => $index_file );
}

#------------------------------------------------------------------------------

sub _build_schema {
  my ($self) = @_;

  my $dbi_config = {RaiseError =>1};
  my $db = $self->config->repos->subdir('db')->file('pinto.db')->absolute();
  return Pinto::Schema->connect("dbi:SQLite:dbname=$db");

}

#------------------------------------------------------------------------------

sub create_db {
  my ($self) = @_;

  my $db_dir = $self->config->repos->subdir('db');
  $self->mkpath($db_dir);

  my $db_file = $db_dir->file('pinto.db');
  my $dbh = DBI->connect("dbi:SQLite:$db_file", undef, undef, {RaiseError =>1})
    or die $DBI::errstr;

  $dbh->do( $_ ) or die $DBI::errstr for creation_sql();

  return 1;
}

#------------------------------------------------------------------------------

sub creation_sql {

return (

'DROP TABLE IF EXISTS distribution;',

'CREATE TABLE distribution (
       location TEXT PRIMARY KEY,
       author TEXT NOT NULL,
       origin TEXT NOT NULL
);',

'DROP TABLE IF EXISTS package;',

'CREATE TABLE package (
       name TEXT PRIMARY KEY,
       version TEXT NOT NULL,
       distribution TEXT NOT NULL,
       FOREIGN KEY(distribution) REFERENCES distribution(location)
);',

);

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

sub load_indexes {
    my ($self) = @_;

    $self->local_index->load();
    $self->master_index->load();

    return $self;
}

#------------------------------------------------------------------------------

sub write_indexes {
    my ($self) = @_;

    $self->local_index->write();
    $self->master_index->write();

    return $self;
}

#------------------------------------------------------------------------------

sub rebuild_master_index {
    my ($self) = @_;

    $self->master_index->clear();
    $self->master_index->add( $self->mirror_index->packages->values->flatten() );
    $self->master_index->add( $self->local_index->packages->values->flatten() );

    return $self;
}

#------------------------------------------------------------------------------

sub remove_local_distribution_at {
    my ($self, %args) = @_;

    my $location = $args{location};

    my $dist = $self->local_index->distributions->at($location);
    return if not $dist;

    $self->local_index->remove_dist($dist);
    $self->logger->debug("Removed $dist from local index");

    $self->master_index->remove_dist($dist);
    $self->logger->debug("Removed $dist from master index");

    return $dist;
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

sub add_local_distribution {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $author = $args{author};

    $self->_distribution_check(%args);

    my $basename   = $file->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $location   = $author_dir->file($basename)->as_foreign('Unix');

    my $added_dist = $self->schema->resultset('Distribution')->create(
        { location => $location, author => $author, origin => 'LOCAL'} );

    my @outdated_packages;
    my @outdated_dists;
    for my $new_pkg ( $self->_extract_packages(file => $file) ) {
      if ( my $old_pkg = $self->schema->resultset('Package')->find( { name => $new_package->{name} } ) ) {
        push @outdated_dists, $old_pkg->distribution();
        push @outdated if $old_pkg;
        $old_pkg->delete();
      }
      $self->schema->resultset('Package')->create( { %{ $package }, distribution => $dist->location->stringify() } );
    }

    $_->delete() if $_->package_count == 0 for @outdated_dists
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

