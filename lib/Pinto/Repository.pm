# ABSTRACT: Coordinates the database, files, and indexes

package Pinto::Repository;

use Moose;

use Carp;
use Class::Load;

use Pinto::Locker;
use Pinto::Database;
use Pinto::IndexCache;
use Pinto::PackageExtractor;
use Pinto::Types qw(Dir);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable
         Pinto::Role::FileFetcher );

#-------------------------------------------------------------------------------

=attr db

=method write_index

=cut

has db => (
    is         => 'ro',
    isa        => 'Pinto::Database',
    lazy       => 1,
    handles    => [ qw(write_index) ],
    default    => sub { Pinto::Database->new( config => $_[0]->config,
                                              logger => $_[0]->logger ) },
);


=attr store

=method initialize()

=method commit()

=method tag()

=cut

has store => (
    is         => 'ro',
    isa        => 'Pinto::Store',
    lazy       => 1,
    handles    => [ qw(initialize commit tag) ],
    default    => sub { my $store_class = $_[0]->config->store;
                        Class::Load::load_class($store_class);
                        $store_class->new( config => $_[0]->config,
                                           logger => $_[0]->logger ) },
);

=attr cache

=method locate( package => );

=method locate( distribution => );

=cut

has cache => (
    is         => 'ro',
    isa        => 'Pinto::IndexCache',
    lazy       => 1,
    does       => [ qw(locate) ],
    default    => sub { Pinto::IndexCache->new( config => $_[0]->config,
                                                logger => $_[0]->logger ) },
);

=method lock

=method unlock

=cut

has locker  => (
    is         => 'ro',
    isa        => 'Pinto::Locker',
    lazy       => 1,
    handles    => [ qw(lock unlock) ],
    default    => sub { Pinto::Locker->new( config => $_[0]->config,
                                            logger => $_[0]->logger ) },
);

=attr extractor

=cut

has extractor => (
    is         => 'ro',
    isa        => 'Pinto::PackageExtractor',
    lazy       => 1,
    default    => sub { Pinto::PackageExtractor->new( config => $_[0]->config,
                                                      logger => $_[0]->logger ) },
);


has revision => (
    is         => 'rw',
    isa        => 'Pinto::Schema::Result::Revision',
    clearer    => 'clear_revision',
    predicate  => 'has_open_revision',
    init_arg   => undef,
);

#-------------------------------------------------------------------------------

=method get_stack( name => $stack_name )

Returns the L<Pinto::Schema::Result::Stack> object with the given
C<$stack_name>.  If there is no stack with such a name in the
repository, returns C<undef>.

=cut

sub get_stack {
    my ($self, %args) = @_;

    my $stk_name = $args{name};

    my $where = { name => $stk_name };
    my $stack = $self->db->select_stacks( $where )->single;

    return $stack;
}

#-------------------------------------------------------------------------------

=method get_package( name => $pkg_name )

Returns the latest version of L<Pinto:Schema::Result::Package> with
the given C<$pkg_name>.  If there is no such package with that name in the
repository, returns nothing.

=method get_package( name => $pkg_name, stack => $stk_name )

Returns the L<Pinto:Schema::Result::Package> with the given
C<$pkg_name> that is on the stack with the given C<$stk_name>. If
there is no such package on that stack, returns nothing.

=cut

sub get_package {
    my ($self, %args) = @_;

    my $pkg_name = $args{name};
    my $stk_name = $args{stack};

    if ($stk_name) {
        my $attrs = { prefetch => [ qw(package stack) ] };
        my $where = { 'package.name' => $pkg_name, 'stack.name' => $stk_name };
        my $pkg_stk = $self->db->select_package_stacks($where, $attrs)->single;
        return $pkg_stk->package;
    }
    else {
        my $where  = { name => $pkg_name };
        my @pkgs   = $self->db->select_packages( $where )->all;
        my $latest = (sort {$a <=> $b} @pkgs)[-1];
        return $latest;
    }
}

#-------------------------------------------------------------------------------

=method get_distribution( path => $dist_path )

Returns the L<Pinto::Schema::Result::Distribution> with the given
C<$dist_path>.  If there is no distribution with such a path in the
respoistory, returns nothing.  Note the C<$dist_path> is a Unix-style
path fragment that identifies the location of the distribution archive
within the repository, such as F<J/JE/JEFF/Pinto-0.033.tar.gz>

=cut

sub get_distribution {
    my ($self, %args) = @_;

    my $dist_path = $args{path};

    my $where = { path => $dist_path };
    my $attrs = { prefetch => 'packages' };
    my $dist  = $self->db->select_distributions( $where, $attrs )->first;

    return $dist;
}

#-------------------------------------------------------------------------------

=method add( archive => $path, author => $id )

=method add( archive => $path, author => $id, source => $url )

Adds the distribution archive located on the local filesystem at
C<$path> to the repository in the author directory for the author with
C<$id>.  The packages provided by the distribution will be indexed,
and the prerequisites will be recorded.  If the the C<source> is
specified, it must be the URL to the root of the repository where the
distribution came from.  Otherwise, the C<source> defaults to
C<LOCAL>.  Returns a L<Pinto::Schema::Result::Distribution> object
representing the newly added distribution.

=cut

sub add {
    my ($self, %args) = @_;

    my $archive = $args{archive};
    my $author  = $args{author};
    my $source  = $args{source} || 'LOCAL';
    my $index   = $args{index}  || 1;  # Is this needed?

    confess "Archive $archive does not exist"  if not -e $archive;
    confess "Archive $archive is not readable" if not -r $archive;

    my $basename   = $archive->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path  = $author_dir->file($basename)->as_foreign('Unix')->stringify();

    $self->get_distribution(path => $dist_path)
        and confess "Distribution $dist_path already exists";

    my $dist_struct = { path     => $dist_path,
                        source   => $source,
                        mtime    => Pinto::Util::mtime($archive),
                        md5      => Pinto::Util::md5($archive),
                        sha256   => Pinto::Util::sha256($archive) };

    my @pkg_specs = $index ? $self->extractor->provides( archive => $archive ) : ();
    $dist_struct->{packages} = \@pkg_specs;

    my $count = $index ? @pkg_specs : '?';
    $self->notice("Adding distribution $dist_path with $count packages");

    # Always update database *before* moving the archive into the
    # repository, so if there is an error in the DB, we can stop and
    # the repository will still be clean.

    my $dist = $self->db->create_distribution( $dist_struct );
    my $repo_archive = $dist->archive( $self->root_dir() );
    $self->fetch( from => $archive, to => $repo_archive );
    $self->store->add_archive( $repo_archive );

    return $dist;
}

#------------------------------------------------------------------------------

=method mirror( struct => {} )

Mirrors a distribution archive from another repository.  The
C<struct> defines the attributes of the distribution and any packages
it contains. TODO: document the members of the struct.  The pacakges
provided by the distribution will not be indexed.  Returns a
L<Pinto::Schema::Result::Distribution> object representing the newly
mirrored distribution.

=cut

sub mirror {
    my ($self, %args) = @_;

    my $struct = $args{struct};

    # TODO: Maybe refactor this to use the add() method
    my $url = URI->new($struct->{source} . '/authors/id/' . $struct->{path});
    $self->info("Mirroring distribution at $url");

    my $temp_archive  = $self->fetch_temporary(url => $url);
    $struct->{mtime}  = Pinto::Util::mtime($temp_archive);
    $struct->{md5}    = Pinto::Util::md5($temp_archive);
    $struct->{sha256} = Pinto::Util::sha256($temp_archive);

    my $dist = $self->db->create_distribution($struct);

    my @path_parts = split m{ / }mx, $struct->{path};
    my $repo_archive = $self->root_dir->file( qw(authors id), @path_parts );
    $self->fetch(from => $temp_archive, to => $repo_archive);
    $self->store->add_archive($repo_archive);

    return $dist;
}

#------------------------------------------------------------------------------

=method pull( url => $url )

Pulls a distribution archive from a remote repository and C<add>s it
to this repository.  The packages provided by the distribution will be
indexed, and the prerequisites will be recorded.  Returns a
L<Pinto::Schema::Result::Distribution> object representing the newly
pulled distribution.

=method pull( package => $spec )

=method pull( distribution => $spec )

=cut

sub pull {
    my ($self, %args) = @_;

    my $url = $args{url};
    my ($source, $path, $author) = Pinto::Util::parse_dist_url( $url );

    my $existing = $self->get_distribution( path => $path );
    confess "Distribution $path already exists" if $existing;

    my $archive = $self->fetch_temporary(url => $url);

    my $dist = $self->add( archive   => $archive,
                           author    => $author,
                           source    => $source );
    return $dist;
}

#-------------------------------------------------------------------------------

=method register( distribution => $dist, stack => $stack )

Registers a distribution to a stack.  All packages in the distribution
will replace those with the same name that are already in the stack.
Returns a true value if the contents of the stack were actually
changed.

=cut

sub register {
    my ($self, %args) = @_;

    my $dist  = $args{distribution};
    my $stack = $args{stack};
    my $did_register = 0;

    $self->info("Registering distribution $dist on stack $stack");
    $did_register += $self->db->register($_, $stack) for $dist->packages;

    return $did_register;
}

#-------------------------------------------------------------------------------

=method unregister( distribution => $dist, stack => $stack )

Unregisters a distribution from a stack.  All packages in the
distribution will be removed from the stack.  Returns a true value if
the contents of the stack were actually changed.

=cut

sub unregister {
    my ($self, %args) = @_;

    my $dist  = $args{distribution};
    my $stack = $args{stack};
    my $did_unregister = 0;

    $self->info("Unregistering distribution $dist from stack $stack");
    $did_unregister += $self->db->unregister($_, $stack) for $dist->packages;

    return $did_unregister;
}

#-------------------------------------------------------------------------------

=method pin( distribution => $dist, stack => $stack )

Pins all the packages in the distribution to the stack.  These
packages cannot be displaced until you unpin them.  Returns a true
value if any packages were actually pinned.

=cut

sub pin {
    my ($self, %args) = @_;

    my $dist    = $args{distribution};
    my $stack   = $args{stack};
    my $did_pin = 0;

    $self->notice("Pinning distribution $dist on stack $stack");
    $did_pin += $self->db->pin($_, $stack) for $dist->packages;

    return $did_pin;

}

#-------------------------------------------------------------------------------

=method unpin( distribution => $dist, stack => $stack )

Unpins all the packages in the distribution from the stack.  These
packages can be displaced.  Returns a true value if any packages were
actually unpinned.

=cut

sub unpin {
    my ($self, %args) = @_;

    my $dist   = $args{distribution};
    my $stack  = $args{stack};
    my $did_unpin = 0;

    $self->notice("Unpinning distribution $dist from stack $stack");
    $did_unpin += $self->db->unpin($_, $stack) for $dist->packages;

    return $did_unpin;
}

#-------------------------------------------------------------------------------

=method create_stack(name => $stk_name, description => $why)

=cut

sub create_stack {
    my ($self, %args) = @_;

    $self->info("Creating stack $args{name}");

    my $stack = $self->db->create_stack( \%args );

    return $stack;

}

#-------------------------------------------------------------------------------

=method remove_stack(name => $stk_name)

=cut

sub remove_stack {
    my ($self, %args) = @_;

    my $stk_name = $args{name};

    $self->fatal( 'You cannot remove the default stack' )
        if $stk_name eq 'default';

    $self->info("Removing stack $stk_name");

    my $stack = $self->get_stack( name => $stk_name );

    $stack->delete;

    return;

}

#-------------------------------------------------------------------------------

=method copy_stack(from => $stack_a, to => $stk_name_b)

=method copy_stack(from => $stack_a, to => $stk_name_b, description => $why)

=cut

sub copy_stack {
    my ($self, %args) = @_;

    my $from_stk_name = $args{from};
    my $to_stk_name   = $args{to};
    my $description   = $args{description};

    $self->info("Creating new stack $to_stk_name");

    my $changes = { name => $to_stk_name };
    $changes->{description} = $description if $description;

    my $from_stack = $self->get_stack(name => $from_stk_name);
    my $to_stack   = $from_stack->copy( $changes );

    $self->info("Copying stack $from_stk_name into stack $to_stk_name");

    for my $packages_stack ( $from_stack->packages_stack ) {
        my $pkg = $packages_stack->package;
        $self->debug("Copying package $pkg into stack $to_stk_name");
        $packages_stack->copy( { stack => $to_stack->id } );
    }

    return $to_stack;
}

#-------------------------------------------------------------------------------

=method merge_stack(from => $stk_name_a, to => $stk_name_b)

=method merge_stack(from => $stk_name_a, to => $stk_name_b, dryrun => 1)

=cut

sub merge_stack {
    my ($self, %args) = @_;

    my $from_stk_name = $args{from};
    my $to_stk_name   = $args{to};
    my $dryrun        = $args{dryrun};


    my $from_stk = $self->repos->get_stack(name => $from_stk_name)
        or confess "Stack $from_stk_name does not exist";

    my $to_stk = $self->repos->get_stack(name => $to_stk_name)
        or confess "Stack $to_stk_name does not exist";

    my $conflicts;
    my $where = { stack => $from_stk->id };
    my $pkg_stk_rs = $self->repos->db->select_package_stacks( $where );


    while ( my $from_pkg_stk = $pkg_stk_rs->next ) {
        $self->info("Merging package $from_pkg_stk into stack $to_stk");
        $conflicts += $self->_merge_pkg_stk( $from_pkg_stk, $to_stk, $dryrun );
    }


    $self->fatal("There were $conflicts conflicts.  Merge aborted")
        if $conflicts and not $dryrun;

    $self->info('Dry run merge -- no changes were made')
        and return if $dryrun;

    # TODO: Add the is_merged field to schema
    # $from_stk->update( {is_merged => 1} );

    return;
}

#------------------------------------------------------------------------------

sub _merge_pkg_stk {
    my ($self, $from_pkg_stk, $to_stk, $dryrun) = @_;

    my $from_pkg   = $from_pkg_stk->package;
    my $attrs      = { prefetch => 'package' };
    my $where      = { 'package.name' => $from_pkg->name,
                       'stack'        => $to_stk->id };

    my $to_pkg_stk = $self->db->select_package_stacks($where, $attrs)->single;

    # CASE 1:  The package does not exist in the target stack,
    # so we can go ahead and just add it there.

    if (not defined $to_pkg_stk) {
         $self->debug("Adding package $from_pkg to stack $to_stk");
         return 0 if $dryrun;
         $from_pkg_stk->copy( {stack => $to_stk} );
         return 0;
     }

    # CASE 2:  The exact same package is in both the source
    # and the target stacks, so we don't have to merge.  But
    # if the source is pinned, then we should also copy the
    # pin to the target.

    if ($from_pkg_stk == $to_pkg_stk) {
        $self->debug("$from_pkg_stk and $to_pkg_stk are the same");
        if ($from_pkg_stk->is_pinned and not $to_pkg_stk->is_pinned) {
            $self->debug("Adding pin to $to_pkg_stk");
            return 0 if $dryrun;
            $to_pkg_stk->update({pin => 1});
            return 0;
        }
        return 0;
    }

    # CASE 3:  The package in the target stack is newer than the
    # one in the source stack.  If the package in the source stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned then there is nothing to do because the package in
    # the target stack is already newer.

    if ($to_pkg_stk > $from_pkg_stk) {
        if ( $from_pkg_stk->is_pinned ) {
            $self->warning("$from_pkg_stk is pinned to a version older than $to_pkg_stk");
            return 1;
        }
        $self->debug("$to_pkg_stk is already newer than $from_pkg_stk");
        return 0;
    }


    # CASE 4:  The package in the target stack is older than the
    # one in the source stack.  If the package in the target stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned, then upgrade the package in the target stack with
    # the newer package in the source stack.

    if ($to_pkg_stk < $from_pkg_stk) {
        if ( $to_pkg_stk->is_pinned ) {
            $self->warning("$to_pkg_stk is pinned to a version older than $from_pkg_stk");
            return 1;
        }
        my $from_pkg = $from_pkg_stk->package();
        $self->info("Upgrading $to_pkg_stk to $from_pkg");
        return 0 if $dryrun;
        $to_pkg_stk->update( {package => $from_pkg} );
        return 0;
    }

    # CASE 5:  The above logic should cover all possible scenarios.
    # So if we get here then either our logic is flawed or something
    # weird has happened in the database.

    confess "Unable to merge $from_pkg_stk into $to_pkg_stk";
}

#-------------------------------------------------------------------------------

=method locate(path = $dist_path)

=method locate(package => $name)

=method locate(package => $name, version => $vers)


=method get_or_locate(path = $dist_path)

=method get_or_locate(package => $name)

=method get_or_locate(package => $name, version => $vers)

=cut

#-------------------------------------------------------------------------------

sub open_revision {
    my ($self, %args) = @_;

    confess 'Revision already in progress' if $self->has_open_revision;

    $self->lock;

    my $revision = $self->db->schema->resultset('Revision')->create(\%args);

    $self->debug('Opened revision ' . $revision->id);

    $self->revision($revision);

    return $self;
}

#-------------------------------------------------------------------------------

sub kill_revision {
    my ($self, %args) = @_;

    confess 'No revision has been opened' if not $self->has_open_revision;

    $self->debug('Killing revision ' . $self->revision->id);

    $self->revision->delete;

    $self->clear_revision;

    $self->unlock;

    return $self;
}

#-------------------------------------------------------------------------------

sub close_revision {
    my ($self, %args) = @_;

    confess 'No revision has been opened' if not $self->has_open_revision;

    $self->debug('Closing revision ' . $self->revision->id);

    $self->revision->update(\%args);

    $self->clear_revision;

    $self->locker->unlock;

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
