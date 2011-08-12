package Pinto::IndexManager;

# ABSTRACT: Manages the indexes of a Pinto repository

use Moose;
use Moose::Autobox;

use Carp;
use Path::Class;

use Pinto::Util;
use Pinto::Index;
use Pinto::UserAgent;

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
packages from both the mirror and local indexes.  See the L<"RULES">
section below for information on how the indexes are combined.

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
with qw( Pinto::Role::Downloadable );

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

    my $local = $self->config->local();
    my $index_file = Path::Class::file($local, 'modules', $args{file});

    return Pinto::Index->new( logger => $self->logger(),
                              file   => $index_file );
}

#------------------------------------------------------------------------------

sub update_mirror_index {
    my ($self) = @_;

    my $local  = $self->config->local();
    my $source = $self->config->source();
    my $force  = $self->config->force();

    my $mirror_index_uri = URI->new("$source/modules/02packages.details.txt.gz");
    my $mirrored_file = Path::Class::file($local, 'modules', '02packages.details.mirror.txt.gz');
    my $has_changed = $self->fetch(url => $mirror_index_uri, to => $mirrored_file);
    $self->logger->info("Index from $source is up to date") unless $has_changed or $force;
    $self->mirror_index->reload() if $has_changed or $force;

    return $has_changed || $force;
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

sub remove_local_package {
    my ($self, %args) = @_;

    my $package = $args{package};
    my $author  = $args{author};

    my $orig_author = $self->local_author_of(package => $package);
    croak "You are $author, but only $orig_author can remove $package"
        if defined $orig_author and $author ne $orig_author;

    my $local_dist = ( $self->local_index->remove($package) )[0];
    return if not $local_dist;

    $self->logger->debug("Removed $local_dist from local index");

    my $master_dist = ( $self->master_index->remove($package) )[0];
    $self->logger->debug("Removed $master_dist from master index");

    $self->rebuild_master_index();

    return $local_dist;
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

    croak 'A distribution already exists at ' . $dist->location()
        if $self->master_index->distributions->at( $dist->location() );

    my @packages = $dist->packages->flatten();
    for my $pkg ( @packages ) {
        if ( my $orig_author = $self->local_author_of(package => $pkg) ) {
            croak sprintf "Package %s is owned by $orig_author", $pkg->name()
              if $orig_author ne $dist->author();
        }
    }

    my @removed_dists = $self->local_index->add(@packages);
    $self->rebuild_master_index();

    return @removed_dists;

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

