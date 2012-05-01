# ABSTRACT: Coordinates the database, files, and indexes

package Pinto::Repository;

use Moose;

use Pinto::Store;
use Pinto::Locker;
use Pinto::Database;
use Pinto::IndexCache;
use Pinto::PackageExtractor;
use Pinto::Exception qw(throw);
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
    default    => sub { Pinto::Store->new( config => $_[0]->config,
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
    handles    => [ qw(locate) ],
    clearer    => 'clear_cache',
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

#-------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    unless (    -e $self->config->db_file
             && -e $self->config->modules_dir
             && -e $self->config->authors_dir ) {

        my $root_dir = $self->config->root_dir();
        throw "Directory $root_dir does not look like a Pinto repository";
    }

    return $self;
}

#-------------------------------------------------------------------------------

=method get_stack()

=method get_stack( name => $stack_name )

=method get_stack( name => $stack_name, nocroak => 1 )

Returns the L<Pinto::Schema::Result::Stack> object with the given
C<$stack_name>.  If there is no stack with such a name in the
repository, throws an exception.  If the C<nocroak> option is true,
than an exception will not be thrown and undef will be returned.  If
you do not specify a stack name (or it is undefined) then you'll get
whatever stack is currently marked as the master stack.

=cut

sub get_stack {
    my ($self, %args) = @_;

    my $stk_name = $args{name};
    return $stk_name if ref $stk_name;  # Is object (or struct) so just return
    return $self->get_master_stack if not $stk_name;

    my $where = { name => $stk_name };
    my $stack = $self->db->select_stack( $where );

    throw "Stack $stk_name does not exist"
        unless $stack or $args{nocroak};

    return $stack;
}

#-------------------------------------------------------------------------------

=method get_master_stack()

Returns the L<Pinto::Schema::Result::Stack> that is currently marked
as the master stack in this repository.  This is what you get when you
call C<get_stack> without any arguments.

At any time, there must be exactly one master stack.  This method will
throw an exception if it discovers that condition is not true.

=cut

sub get_master_stack {
    my ($self) = @_;

    my $where = {is_master => 1};
    my @stacks = $self->db->select_stacks( $where )->all;

    throw "PANIC! There must be exactly one master stack" if @stacks != 1;

    return $stacks[0];
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
    my $pkg_vers = $args{version}; # ??
    my $stk_name = $args{stack};

    if ($stk_name) {
        my $stack = $self->get_stack(name => $stk_name);
        my $attrs = { prefetch => 'package' };
        my $where = { package_name => $pkg_name, stack => $stack->id };
        my $registration = $self->db->select_registration($where, $attrs);
        return $registration ? $registration->package : ();
    }
    else {
        my $where  = { name => $pkg_name };
        my @pkgs   = $self->db->select_packages( $where )->all;
        my $latest = (sort {$a <=> $b} @pkgs)[-1];
        return $latest ? $latest : ();
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

    throw "Archive $archive does not exist"  if not -e $archive;
    throw "Archive $archive is not readable" if not -r $archive;

    my $basename   = $archive->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path  = $author_dir->file($basename)->as_foreign('Unix')->stringify();

    $self->get_distribution(path => $dist_path)
        and throw "Distribution $dist_path already exists";

    # Assemble the basic structure...
    my $dist_struct = { path     => $dist_path,
                        source   => $source,
                        mtime    => Pinto::Util::mtime($archive),
                        md5      => Pinto::Util::md5($archive),
                        sha256   => Pinto::Util::sha256($archive) };

    # Add provided packages...
    my @provides = $self->extractor->provides( archive => $archive );
    $dist_struct->{packages} = \@provides;

    # Add required packages...
    my @requires = $self->extractor->requires( archive => $archive );
    $dist_struct->{prerequisites} = \@requires;

    my $p = @provides;
    my $r = @requires;
    $self->info("Archvie $dist_path provides $p and requires $r packages");

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

    throw "Distribution $path already exists"
        if $self->get_distribution( path => $path );

    my $archive = $self->fetch_temporary(url => $url);

    my $dist = $self->add( archive   => $archive,
                           author    => $author,
                           source    => $source );
    return $dist;
}

#-------------------------------------------------------------------------------

=method create_stack(name => $stk_name, properties => { $key => $value, ... } )

=cut

sub create_stack {
    my ($self, %args) = @_;

    my $name  = Pinto::Util::normalize_stack_name($args{name});
    my $props = $args{properties};

    throw "Stack $name already exists"
        if $self->get_stack(name => $name, nocroak => 1);

    my $stack = $self->db->create_stack( {name => $name} );
    $stack->set_properties($props) if $props;

    return $stack;

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


    my $from_stk = $self->get_stack(name => $from_stk_name);
    my $to_stk   = $self->get_stack(name => $to_stk_name);

    my $conflicts;
    my $where = { stack => $from_stk->id };
    my $registration_rs = $self->db->select_registrations( $where );


    while ( my $from_registration = $registration_rs->next ) {
        $self->info("Merging package $from_registration into stack $to_stk");
        $conflicts += $self->_merge_registration($from_registration, $to_stk, $dryrun);
    }


    throw "There were $conflicts conflicts.  Merge aborted"
        if $conflicts and not $dryrun;

    $self->info('Dry run merge -- no changes were made')
        and return if $dryrun;

    # TODO: Add the is_merged field to schema
    # $from_stk->update( {is_merged => 1} );

    return;
}

#------------------------------------------------------------------------------

sub _merge_registration {
    my ($self, $from_registration, $to_stk, $dryrun) = @_;

    my $from_pkg    = $from_registration->package;
    my $attrs       = {prefetch => 'package'};
    my $where       = {package_name  => $from_pkg->name, stack => $to_stk->id};
    my $to_registration = $self->db->select_registration($where, $attrs);

    # CASE 1:  The package does not exist in the target stack,
    # so we can go ahead and just add it there.

    if (not defined $to_registration) {
         $self->debug("Adding package $from_pkg to stack $to_stk");
         return 0 if $dryrun;
         $from_registration->copy( {stack => $to_stk} );
         return 0;
     }

    # CASE 2:  The exact same package is in both the source
    # and the target stacks, so we don't have to merge.  But
    # if the source is pinned, then we should also copy the
    # pin to the target.

    if ($from_registration == $to_registration) {
        $self->debug("$from_registration and $to_registration are the same");
        if ($from_registration->is_pinned and not $to_registration->is_pinned) {
            $self->debug("Adding pin to $to_registration");
            return 0 if $dryrun;
            $to_registration->update({pin => 1});
            return 0;
        }
        return 0;
    }

    # CASE 3:  The package in the target stack is newer than the
    # one in the source stack.  If the package in the source stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned then there is nothing to do because the package in
    # the target stack is already newer.

    if ($to_registration > $from_registration) {
        if ( $from_registration->is_pinned ) {
            $self->warning("$from_registration is pinned to a version older than $to_registration");
            return 1;
        }
        $self->debug("$to_registration is already newer than $from_registration");
        return 0;
    }


    # CASE 4:  The package in the target stack is older than the
    # one in the source stack.  If the package in the target stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned, then upgrade the package in the target stack with
    # the newer package in the source stack.

    if ($to_registration < $from_registration) {
        if ( $to_registration->is_pinned ) {
            $self->warning("$to_registration is pinned to a version older than $from_registration");
            return 1;
        }
        my $from_pkg = $from_registration->package();
        $self->info("Upgrading $to_registration to $from_pkg");
        return 0 if $dryrun;
        $to_registration->update( {package => $from_pkg} );
        return 0;
    }

    # CASE 5:  The above logic should cover all possible scenarios.
    # So if we get here then either our logic is flawed or something
    # weird has happened in the database.

    throw "Unable to merge $from_registration into $to_registration";
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

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
