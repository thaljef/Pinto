package Pinto::IndexManager;

# ABSTRACT: Manages the indexes of a Pinto repository

use Moose;
use Moose::Autobox;

use Path::Class;

use Pinto::Util;
use Pinto::Index;
use Pinto::UserAgent;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has 'ua'  => (
    is         => 'ro',
    isa        => 'Pinto::UserAgent',
    default    => sub { Pinto::UserAgent->new() },
    handles    => [qw(mirror)],
    init_arg   => undef,
);

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

with qw(Pinto::Role::Configurable Pinto::Role::Loggable);

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

    my $local = $self->config()->local();
    my $index_file = Path::Class::file($local, 'modules', $args{file});
    return Pinto::Index->new(file => $index_file);
}

#------------------------------------------------------------------------------

sub rebuild_master_index {
    my ($self) = @_;


    $self->logger()->debug("(Re)building master index");

    $self->master_index()->clear();
    $self->master_index()->add( $self->mirror_index()->packages()->values()->flatten() );
    $self->master_index()->merge( $self->local_index()->packages()->values()->flatten() );

    return $self->master_index();
}

#------------------------------------------------------------------------------

sub update_mirror_index {
    my ($self) = @_;

    my $local  = $self->config()->local();
    my $mirror = $self->config()->mirror();

    # TODO: Make an Index subclass for the mirror index, which knows
    # how to update itself from a remote source.  Maybe optimize
    # to reduce the number of times we have to read the index file.

    my $mirror_index_uri = URI->new("$mirror/modules/02packages.details.txt.gz");
    my $mirrored_file = Path::Class::file($local, 'modules', '02packages.details.mirror.txt.gz');
    my $file_has_changed = $self->ua()->mirror(url => $mirror_index_uri, to => $mirrored_file);
    $self->mirror_index()->reload() if $file_has_changed;

    return $file_has_changed;
}

#------------------------------------------------------------------------------

sub files_to_mirror {
    my ($self) = @_;

    return ($self->mirror_index() - $self->local_index())->files()
                                                         ->keys()
                                                         ->sort()
                                                         ->flatten();
}

#------------------------------------------------------------------------------

sub all_packages {
    my ($self) = @_;

    my $sorter = sub { $_[0]->name() cmp $_[1]->name() };
    return $self->master_index()->packages()->values->sort($sorter)->flatten();
}

#------------------------------------------------------------------------------

sub write_indexes {
    my ($self) = @_;

    $self->local_index->write();
    $self->rebuild_master_index()->write();

    return $self;
}

#------------------------------------------------------------------------------

sub remove_local_package {
    my ($self, %args) = @_;

    my $package = $args{package};

    my @local_removed = $self->local_index()->remove($package);
    $self->logger->debug("Removed $_ from local index")
      for @local_removed->map( sub {$_[0]->name()} )->flatten();

    return if not @local_removed;

    my @master_removed = $self->master_index()->remove($package);
    $self->logger->debug("Removed $_ from master index")
      for @master_removed->map( sub {$_[0]->name()} )->flatten();

    # TODO: Sanity check - packages removed from the local and the
    # master indexes should always be the same.

    return sort map {$_->name()} @local_removed;
}

#------------------------------------------------------------------------------

sub local_author_of {
    my ($self, %args) = @_;

    my $package = $args{package};

    my $pkg = $self->local_index()->packages()->at($package);

    return $pkg ? $pkg->author() : ();
}


#------------------------------------------------------------------------------

sub find_file {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $author = $args{author};

    my $local         = $self->config()->local();
    my $author_dir    = Pinto::Util::directory_for_author($local, qw(authors id), $author);
    my $physical_file = Path::Class::file($author_dir, $file->basename());
    return -e $physical_file ? $physical_file : ();
}

#------------------------------------------------------------------------------

sub add_local_package {
    my ($self, %args) = @_;

    my $package = Pinto::Package->new(%args);
    $self->local_index()->add($package);

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta()->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
