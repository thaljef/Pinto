package Pinto;

# ABSTRACT: Perl archive repository manager

use Moose;

use Pinto::Util;
use Pinto::Index;
use Pinto::Config;
use Pinto::UserAgent;

use Carp;
use File::Copy;
use File::Find;
use Dist::MetaData;
use Path::Class;
use URI;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

=attr profile

Returns the path to your L<Pinto> configuration file.  If you do not
specify one through the constructor, then we look at C<$ENV{PINTO}>,
then F<~/.pinto/config.ini>.  If the config file does not exist in any
of those locations, then you'll get an empty config.

=cut

has 'profile' => (
    is           => 'ro',
    isa          => 'Str',
);

=attr config

Returns the L<Pinto::Config> object for this Pinto.  You may provide
one through the constructor.  Otherwise one will be created from the
file specified by the C<profile> attribute.

=cut

has 'config' => (
    is       => 'ro',
    isa      => 'Pinto::Config',
    builder  => '_build_config',
    lazy     => 1,
);

has '_ua'      => (
    is         => 'ro',
    isa        => 'Pinto::UserAgent',
    default    => sub { Pinto::UserAgent->new() },
    handles    => [qw(mirror)],
    init_arg   => undef,
);

=attr remote_index

Returns the L<Pinto::Index> that represents our copy of the
F<02packages> file from a CPAN mirror (or possibly another Pinto
repository).  This index will include all the packages on the mirror,
except those that you've chosen to deliberately filter out.

=cut

has 'remote_index' => (
    is             => 'ro',
    isa            => 'Pinto::Index',
    builder        => '_build_remote_index',
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
    builder         => '_build_local_index',
    init_arg        => undef,
    lazy            => 1,
);

=attr master_index

Returns the L<Pinto::Index> that is the logical combination of
packages from both the remote and local indexes.  See the L<"RULES">
section below for information on how the indexes are combined.

=cut

has 'master_index'  => (
    is              => 'ro',
    isa             => 'Pinto::Index',
    builder         => '_build_master_index',
    init_arg        => undef,
    lazy            => 1,
);

#------------------------------------------------------------------------------
# Roles

with 'Pinto::Role::Log';

#------------------------------------------------------------------------------
# Builders

sub _build_config {
    my ($self) = @_;
    return Pinto::Config->new(profile => $self->profile());
}

#------------------------------------------------------------------------------

sub _build_remote_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.remote.txt.gz');
}

#------------------------------------------------------------------------------

sub _build_local_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.local.txt.gz');
}

#------------------------------------------------------------------------------

sub _build_master_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.txt.gz');
}

#------------------------------------------------------------------------------

sub __build_index {
    my ($self, %args) = @_;

    my $local = $self->config()->{_}->{local};
    my $index_file = file($local, 'modules', $args{file});

    return Pinto::Index->new(file => $index_file);
}

#------------------------------------------------------------------------------
# Private methods

sub _rebuild_master_index {
    my ($self) = @_;

    $self->log()->debug("Rebuilding master index");

    $self->master_index()->clear();
    $self->master_index()->add( @{$self->remote_index()->packages()} );
    $self->master_index()->merge( @{$self->local_index()->packages()} );

    $self->master_index()->write();

    return $self;
}

#------------------------------------------------------------------------------

=method create(local => 'path/to/local/repository')

Creates a new empty repoistory

=cut

sub create {
    my ($self, %args) = @_;

    $self->local_index()->write();

    return $self;
}

#------------------------------------------------------------------------------

=method update(local => 'path/to/local/repository', remote => 'http://cpan-mirror')

Loads your repository with the latest version of all packages found on
the CPAN mirror.

=cut

sub update {
    my ($self, %args) = @_;

    my $local  = $args{local}  || $self->config()->{_}->{local};
    my $remote = $args{remote} || $self->config()->{_}->{remote};

    my $remote_index_uri = URI->new("$remote/modules/02packages.details.txt.gz");
    $self->mirror(url => $remote_index_uri, to => $self->remote_index()->file());
    $self->remote_index()->reload();

    my $changes = 0;
    my $mirrorable_index = $self->remote_index() - $self->local_index();

    for my $file ( @{ $mirrorable_index->files() } ) {
        $self->log()->debug("Mirroring $file");
        my $remote_uri = URI->new( "$remote/authors/id/$file" );
        my $destination = Pinto::Util::native_file($local, 'authors', 'id', $file);
        my $changed = $self->mirror(url => $remote_uri, to => $destination);
        $self->log->info("Updated $file") if $changed;
    }

    $self->_rebuild_master_index();

    return $self;
}

#------------------------------------------------------------------------------

=method add(local => 'path/to/local/repository', author => 'YOUR_ID', file => 'YourDist.tar.gz')

Adds your own Perl archive to the repository.  This could be a
proprietary or personal archive, or it could be a patched version of
an archive from a CPAN mirror.  See the L<"RULES"> section for
information about how your archives are combined with those from the
CPAN mirror.

=cut

sub add {
    my ($self, %args) = @_;

    my $local  = $args{local}  || $self->config()->{_}->{local};
    my $author = $args{author} || $self->config()->{_}->{author};
    my $file   = $args{file};

    $file = file($file) if not eval { $file->isa('Path::Class::File') };

    my $distmeta = Dist::Metadata->new(file => $file);
    my $provides = $distmeta->package_versions();

    my $author_dir    = Pinto::Util::directory_for_author($author);
    my $file_in_index = file($author_dir, $file->basename())->as_foreign('Unix');

    if (my $existing_file = $self->local_index()->packages_by_file->{$file_in_index}) {
        croak "File '$file_in_index' already exists in the local index";
    }

    my @packages = ();
    while( my ($pkg, $ver) = each %{ $provides } ){
        $self->log->info("Adding $pkg $ver");
        push @packages, Pinto::Package->new(name => $pkg, version => $ver, file => "$file_in_index");
    }

    $self->local_index->add(@packages);
    $self->local_index()->write();

    my $destination_dir = Pinto::Util::directory_for_author($local, qw(authors id), $author);
    $destination_dir->mkpath();  #TODO: log & error check
    copy($file, $destination_dir); #TODO: log & error check

    $self->_rebuild_master_index();

    return $self;
}

#------------------------------------------------------------------------------

=method remove(local => 'path/to/local/repository', author => 'YOUR_ID', package => 'Some::Package')

Removes packages from the local index.  When a package is removed, all
other packages that were contained in the same archive are also
removed.  You can only remove a package if you are the author of that
package.

=cut

sub remove {
    my ($self, %args) = @_;

    my $local   = $args{local}  || $self->config()->{_}->{local};
    my $package = $args{package};

    # TODO: Only allow authors to remove their own packages

    my @local_removed = $self->local_index()->remove($package);
    $self->log->info("Removed $_ from local index") for @local_removed;
    $self->local_index()->write();

    my @master_removed = $self->master_index()->remove($package);
    $self->log->info("Removed $_ from master index") for @master_removed;
    $self->master_index()->write();

    # Do not rebuild master index after removing packages,
    # or else the packages from the remote index will appear.

    return $self;
}

#------------------------------------------------------------------------------

=method clean(local => 'path/to/local/repository')

Deletes any archives in the repository that are not currently
represented in the master index.  You'll usually want to run this
after performing an C<"update">, C<"add">, or C<"remove"> operation.

=cut

sub clean {
    my ($self, %args) = @_;
    my $local = $args{local} || $self->config()->{_}->{local};
    my $base_dir = dir($local, qw(authors id));

    my $wanted = sub {
        $DB::single = 1;
        my $physical_file = file($File::Find::name);
        my $logical_file  = $physical_file->relative($base_dir)->as_foreign('Unix');

        # TODO: Can we just use $_ instead of calling basename() ?
        if (Pinto::Util::is_source_control_file( $physical_file->basename() )) {
            $File::Find::prune = 1;
            return;
        }

        return if not -f $physical_file;
        return if exists $self->master_index()->packages_by_file()->{$logical_file};
        $self->log()->info("Cleaning $logical_file"); # TODO: report as physical file instead?
        $physical_file->remove(); # TODO: Error check!
    };

    # TODO: Consider using Path::Class::Dir->recurse() instead;
    File::Find::find($wanted, $base_dir);

    return $self;
}

#------------------------------------------------------------------------------

=method list(local => 'path/to/local/repository')

Prints a listing of all the packages and archives in the master index.
This is basically what the F<02packages> file looks like.

=cut

sub list {
    my ($self) = @_;

    for my $package ( @{ $self->master_index()->packages() } ) {
        # TODO: Report native paths instead?
        print $package->to_string(), "\n";
    }

    return $self;
}

#------------------------------------------------------------------------------

=method verify(local => 'path/to/local/repository')

Prints a listing of all the archives that are in the master index, but
are not present in the repository.  This is usually a sign that things
have gone wrong.

=cut

sub verify {
    my ($self) = @_;
    my $local = $self->config()->{_}->{local};

    my @base = ($local, 'authors', 'id');
    for my $file ( @{ $self->master_index()->files_native(@base) } ) {
        # TODO: Report full or relative path?
        print "$file is missing\n" if not -e $file;
    }

    return $self;
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 DESCRIPTION

You probably want to look at the documentation for L<pinto>.  This is
a private module (for now) and the interface is subject to change.  So
the API documentation is purely for my own reference.  But this
document does explain what Pinto does and why it exists, so feel free
to read on anyway.

=head1 TERMINOLOGY

Some of the terms around CPAN are frequently misused.  So for the
purpose of this document, I'm going to define some terms.  I'm not
saying that these are necessarily the "correct" definitions, but
I think they are pretty reasonable.

=over 4

=item package

A "package" is the name that appears in a C<package> statement.  This
is what PAUSE indexes, and this is what you usually ask L<cpan> or
L<cpanm> to install for you.

=item module

A "module" is the name that appears in a C<use> or (sometimes)
C<require> statement, and it always corresponds to a physical file
somewhere.  A module usually contains only one package, and the name
of the module usually matches the name of the package.  But sometimes,
a module may contain many packages with completely arbitrary names.

=item archive

An "archive" is a collection of Perl modules that have been packaged
in a particular structure.  This is what you get when you run C<"make
dist"> or C<"./Build dist">.  Archives may come from a "mirror",
or you may create your own.

=item repository

A "repository" is a collection of archives that are organized in a
particular structure, and having an index describing which packages
are contained in each archive.  This is where L<cpan> and L<cpanm>
get the packages from.

=item mirror

A "mirror" is a copy of a public CPAN repository
(e.g. http://cpan.perl.org).  Every "mirror" is a "repository", but
not every "repository" is a "mirror".

=back

=head1 RULES

There are certain rules that govern how the indexes are managed.
These rules are intended to ensure that folks pulling packages
from your repository will always get the *right  Also,
the rules attempt to make Pinto behave somewhat like PAUSE does.

=over 4

=item A local package always masks a mirrored package, and all other
packages that are in the same archive with the mirrored package.

This rule is key, so pay attention.  If the CPAN mirror has an archive
that contains both C<Foo> and C<Bar> packages, and you add your own
archive that contains C<Foo> package, then both the C<Foo> and C<Bar>
mirroed packages will be removed from your index.  This ensures that
anyone pulling packages from your repository will always get *your*
C<Foo>.  But they'll never be able to get C<Bar>.

If this rule were not in place, someone could pull C<Bar> from the
repository, which would overwrite the version of C<Foo> that you
wanted them to have.  This situation is probably rare, but it can
happen if you add a locally patched version of a mirrored archive, but
the mirrored archive later includes additional packages.

=item You can never add an archive with the same name twice.

Most archive-building tools will put some kind of version number in
the name of the archive, so this is rarely a problem.

=item Only the original author of a local package can add a newer
version of it.

Ownership is given on a first-come basis, just like PAUSE.  So if
C<SALLY> is the first author to add local package C<Foo::Bar> to the
repository, then only C<SALLY> can ever add that package again.

=item Only the original author of a local package can remove it.

Just like when adding new versions of a local package, only the
original author can remove it.

=back

=head1 WHY IS IT CALLED "Pinto"

The term "CPAN" is heavily overloaded.  In some contexts, it means the
L<CPAN> module or the L<cpan> utility.  In other contexts, it means a
mirror like L<http://cpan.perl.org> or a site like
L<http://search.cpan.org>.

I wanted to avoid confusion, so I picked a name that has no connection
to "CPAN".  "Pinto" is a nickname that I sometimes call my son,
Wesley.  Daddy loves you, Wes!

=head1 THANKS

=item Randal Schwartz - for pioneering the first mini CPAN back in 2002

=item Ricardo Signes - for creating CPAN::Mini, which inspired much of Pinto

=item Shawn Sorichetti & Christian Walde - for creating CPAN::Mini::Inject

=cut
