package Pinto::IndexManager;

# ABSTRACT: Manages the indexes of a Pinto repository

use Moose;
use Moose::Autobox;

use Path::Class;
use File::Compare;

use Pinto::Util;
use Pinto::Index;
use Pinto::Exception::Unauthorized;
use Pinto::Exception::DuplicateDist;
use Pinto::Exception::IllegalDist;

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

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

# HACK: I'm not sure why the required method isn't found
# when I load all my roles at once.
with qw( Pinto::Role::UserAgent );

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

sub local_author_of {
    my ($self, %args) = @_;

    my $package = $args{package};
    $package = $package->name() if eval {$package->isa('Pinto::Package')};

    my $pkg = $self->local_index->packages->at($package);

    return if not $pkg;
    return $pkg->dist->author();
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

    my $dist = $args{dist};
    my $file = $args{file};

    $self->_distribution_check($dist, $file);

    my @packages = $dist->packages->flatten();

    for my $pkg ( @packages ) {

        my $orig_author = $self->local_author_of(package => $pkg);
        next if not $orig_author;

        if ( $orig_author ne $dist->author() ) {
            my $msg = "Only author $orig_author can update $pkg";
            Pinto::Exception::Unauthorized->throw($msg);
        }
    }

    my @removed_dists = $self->local_index->add(@packages);
    $self->rebuild_master_index();

    return @removed_dists;

}

#------------------------------------------------------------------------------

sub _distribution_check {
    my ($self, $new_dist, $new_file) = @_;

    my $location = $new_dist->location();
    my $existing_dist = $self->master_index->distributions->at($location);
    return 1 if not $existing_dist;

    my $existing_path = $existing_dist->path( $self->config->repos() );
    return 1 if not -e $existing_path;

    my $is_same = !compare($existing_path, $new_file);

    # TODO: One of these situations is a lot more important than the
    # other, so we need to trap the exceptions and handle them
    # accordingly.  A different dist warrants a loud warning.  But the
    # same dist only needs a whimper.

    if (not $is_same) {
        my $msg = "A different distribution already exists as $location";
        Pinto::Exception::IllegalDist->throw($msg);
    }
    else {
        my $msg = "The same distribution already exists at $location";
        Pinto::Exception::DuplicateDist->throw($msg);
    }

    return 1;  # should never get here
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

