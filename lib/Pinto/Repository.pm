# ABSTRACT: Coordinates the database, files, and indexes

package Pinto::Repository;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods (autoclean => 1);

use Readonly;
use File::Find;
use Path::Class;

use Pinto::Store;
use Pinto::Config;
use Pinto::Locker;
use Pinto::Database;
use Pinto::IndexCache;
use Pinto::PackageExtractor;
use Pinto::PrerequisiteWalker;
use Pinto::Util qw(itis debug mksymlink throw);
use Pinto::Types qw(Dir);

use version;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

Readonly::Scalar our $REPOSITORY_VERSION => 1;

#-------------------------------------------------------------------------------

with qw( Pinto::Role::FileFetcher );

#-------------------------------------------------------------------------------

=attr root

=cut

has root => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

=attr config

=cut

has config => (
    is         => 'ro',
    isa        => 'Pinto::Config',
    default    => sub { Pinto::Config->new(root => $_[0]->root) },
    lazy       => 1,
);

=attr db

=cut

has db => (
    is         => 'ro',
    isa        => 'Pinto::Database',
    default    => sub { Pinto::Database->new(repo => $_[0]) },
    lazy       => 1,
);

=attr store

=cut

has store => (
    is         => 'ro',
    isa        => 'Pinto::Store',
    default    => sub { Pinto::Store->new(repo => $_[0]) },
    lazy       => 1,
);

=attr cache

=method locate( package => );

=method locate( distribution => );

=cut

has cache => (
    is         => 'ro',
    isa        => 'Pinto::IndexCache',
    handles    => [ qw(locate) ],
    clearer    => '_clear_cache',
    default    => sub { Pinto::IndexCache->new(repo => $_[0]) },
    lazy       => 1,
);

=attr locker

=method lock( $LOCK_TYPE )

=method unlock

=cut

has locker  => (
    is         => 'ro',
    isa        => 'Pinto::Locker',
    handles    => [ qw(lock unlock) ],
    default    => sub { Pinto::Locker->new(repo => $_[0]) },
    lazy       => 1,
);

#-------------------------------------------------------------------------------

=method get_stack()

=method get_stack( $stack_name )

=method get_stack( $stack_object )

=method get_stack( $stack_name_or_object, nocroak => 1 )

Returns the L<Pinto::Schema::Result::Stack> object with the given
C<$stack_name>.  If the argument is a L<Pinto::Schema::Result::Stack>,
then it just returns that.  If there is no stack with such a name in the
repository, throws an exception.  If the C<nocroak> option is true,
than an exception will not be thrown and undef will be returned.  If
you do not specify a stack name (or it is undefined) then you'll get
whatever stack is currently marked as the default stack.

The stack object will not be open for revision, so you will not be
able to change any of the registrations for that stack.  To get a
stack that you can modify, use C<open_stack>.

=cut

sub get_stack {
    my ($self, $stack, %opts) = @_;

    return $stack if itis($stack, 'Pinto::Schema::Result::Stack');
    return $self->get_default_stack if not $stack;

    my $where = { name => $stack };
    my $got_stack = $self->db->schema->find_stack( $where );

    throw "Stack $stack does not exist"
        unless $got_stack or $opts{nocroak};

    return $got_stack;
}

#-------------------------------------------------------------------------------

=method get_default_stack()

Returns the L<Pinto::Schema::Result::Stack> that is currently marked
as the default stack in this repository.  This is what you get when you
call C<get_stack> without any arguments.

The stack object will not be open for revision, so you will not be
able to change any of the registrations for that stack.  To get a
stack that you can modify, use C<open_stack>.

At any time, there must be exactly one default stack.  This method will
throw an exception if it discovers that condition is not true.

=cut

sub get_default_stack {
    my ($self) = @_;

    my $where = {is_default => 1};
    my @stacks = $self->db->schema->search_stack( $where )->all;

    # Assert that there is no more than one default stack
    throw "PANIC: There must be no more than one default stack" if @stacks > 1;

    # Error if the default stack has been set
    throw "The default stack has not been set" if @stacks == 0;

    return $stacks[0];
}

#-------------------------------------------------------------------------------

=method get_all_stacks()

Returns a list of all the L<Pinto::Schema::Result::Stack> objects in the
repository.  You can sort them as strings (by name) or numerically (by
last modification time).

=cut

sub get_all_stacks {
    my ($self) = @_;

    return $self->db->schema->stack_rs->all;
}

#-------------------------------------------------------------------------------

=method get_revision($commit)

=cut

sub get_revision {
    my ($self, $revision) = @_;

    return $revision if itis($revision, 'Pinto::Schema::Result::Revision');

    my @revs = $self->db->schema->search_revision( {uuid => {like => $revision}} );

    throw "Revision id $revision is ambiguous" if @revs > 1;

    return @revs ? $revs[0] : ();
}

#-------------------------------------------------------------------------------

=method get_package( spec => $pkg_spec )

Returns a L<Pinto:Schema::Result::Package> representing the latest
version of the package in the repository with the same name as
the package spec B<and the same or higher version> as the package 
spec.  See L<Pinto::PackageSpec> for the definition of a package
spec.

=method get_package( name => $pkg_name )

Returns a L<Pinto:Schema::Result::Package> representing the latest
version of the package in the repostiory with the given C<$pkg_name>.  
If there is no such package with that name in the repository, 
returns nothing.

=method get_package( name => $pkg_name, path => $dist_path )

Returns the L<Pinto:Schema::Result::Package> with the given
C<$pkg_name> that belongs to the distribution identified by 
C<$dist_path>. If there is no such package in the repository, 
returns nothing.

=cut

sub get_package {
    my ($self, %args) = @_;

    my $spec      = $args{spec};
    my $pkg_name  = $args{name};
    my $dist_path = $args{path};

    # Retrieve latest version of package that meets the spec
    if ($spec) {
        my $pkg_name = $spec->name;
        my $version  = $spec->version;

        my @pkgs = $self->db->schema->search_package({name => $pkg_name})->with_distribution;
        my $latest = (sort {$a <=> $b} @pkgs)[-1];

        return $latest->version >= $spec->version ? $latest : ();
    }


    # Retrieve package from a specific distribution
    elsif ($pkg_name && $dist_path) {

        my ($author, $archive) = Pinto::Util::parse_dist_path($dist_path);

        my $where = { 'me.name'              => $pkg_name, 
                      'distribution.author'  => $author,
                      'distribution.archive' => $archive };

        my @pkgs = $self->db->schema->search_package($where)->with_distribution;

        return @pkgs ? $pkgs[0] : ();
    }


    # Retrieve latest version of package in the entire repository
    elsif ($pkg_name) {

        my $where  = { name => $pkg_name };
        my @pkgs   = $self->db->schema->search_package($where)->with_distribution;

        my $latest = (sort {$a <=> $b} @pkgs)[-1];
        return defined $latest ? $latest : ();
    }

    throw 'Invalid arguments';
}

#-------------------------------------------------------------------------------

=method get_distribution( spec => $pkg_spec )

Given a L<Pinto::PackageSpec>, returns the L<Pinto::Schema::Result::Distribution>
that contains the B<latest version of the package> in this repository with the same 
name as the spec B<and the same or higher version as the spec>.  Returns nothing 
if no such distribution is found.

=method get_distribution( spec => $dist_spec )

Given a L<Pinto::DistributionSpec>, returns the L<Pinto::Schema::Result::Distribution>
from this repository with the same author id and archive attributes as the spec.  
Returns nothing if no such distribution is found.

=method get_distribution( path => $dist_path )

Given a distribution path, (for example C<AUTHOR/Dist-1.0.tar.gz> or C<A/AU/AUTHOR/Dist-1.0.tar.gz>
returns the L<Pinto::Schema::Result::Distribution> from this repository that is 
identified by the author ID and archive file name in the path.  Returns nothing
if no such distribution is found.

=method get_distribution( sha256 => $sha256 )

Given an SHA-256 digest as a string of hexadecimal characters, returns the
L<Pinto::Schema::Result::Distribution> from this repository with the same 
digest.  Returns nothing if no such distribution is found.

=method get_distribution( author => $author, archive => $archive )

Given an author id and a distribution archive file basename, returns the 
L<Pinto::Schema::Result::Distribution> from this repository with those
attributes.  Returns nothing if no such distribution exists.

=cut

sub get_distribution {
    my ($self, %args) = @_;

    # Retrieve a distribution by DistSpec or PackageSpec
    if (my $spec = $args{spec}) {
        if ( itis($spec, 'Pinto::DistributionSpec') ) {
            my $author  = $spec->author_canonical;
            my $archive = $spec->archive;

            return $self->db->schema->distribution_rs
                                    ->with_packages
                                    ->find_by_author_archive($author, $archive);
        }
        elsif ( itis($spec, 'Pinto::PackageSpec') ) {
            my $pkg = $self->get_package(name => $spec->name);
            return () if ! defined($pkg) or $pkg->version < $spec->version;
            return $pkg->distribution;
        } 

        throw 'Invalid arguments';
    }


    # Retrieve a distribution by its path (e.g. AUTHOR/Dist-1.0.tar.gz)
    elsif (my $path = $args{path}) {
        my ($author, $archive) = Pinto::Util::parse_dist_path($path);

        return $self->db->schema->distribution_rs
                                ->with_packages
                                ->find_by_author_archive($author, $archive);
    }


    # Retrieve a distribution by its SHA-256 digest
    elsif (my $sha256 = $args{sha256}) {
         return $self->db->schema->distribution_rs
                                 ->with_packages
                                 ->find_by_sha256($sha256);
    }


    # Retrieve a distribution by its MD5 digest
    elsif (my $md5 = $args{md5}) {
         return $self->db->schema->distribution_rs
                                 ->with_packages
                                 ->find_by_md5($md5);
    }

    # Retrieve a distribution by author and archive
    elsif (my $author = $args{author}) {
        my $archive = $args{archive} or throw "Must specify archive with author";

        return $self->db->schema->distribution_rs
                                ->with_packages
                                ->find_by_author_archive($author, $archive);
    }

    throw 'Invalid arguments';
}

#-------------------------------------------------------------------------------

=method ups_distribution( spec => $pkg_spec )

Given a L<Pinto::PackageSpec>, locates the distribution that contains the latest
version of the package across all upstream repositories with the same name as 
the spec, and the same or higher version as the spec.  If such distribution is
found, it is fetched and added to this repository.  If it is not found,
then an exception is thrown.

=method ups_distribution( spec => $dist_spec )

Given a L<Pinto::DistributionSpec>, locates the first distribution in any 
upstream repository with the same author and archive as the spec.  If such 
distribution is found, it is fetched and added to this repository.  If it 
is not found, then an exception is thrown.

=cut

sub ups_distribution {
    my ($self, %args) = @_;

    my $spec = $args{spec};
    my $dist_url;

    if ( Pinto::Util::itis($spec, 'Pinto::PackageSpec') ){
        $dist_url = $self->locate(package => $spec->name, version => $spec->version, latest => 1);
    }
    elsif ( Pinto::Util::itis($spec, 'Pinto::DistributionSpec') ){
        $dist_url = $self->locate(distribution => $spec->path)
    }
    else {
        throw 'Invalid arguments';
    }

    throw "Cannot find $spec anywhere" if not $dist_url;

    return $self->fetch_distribution(url => $dist_url);
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

sub add_distribution {
    my ($self, %args) = @_;

    my $archive = $args{archive};
    my $author  = uc $args{author};
    my $source  = $args{source} || 'LOCAL';

    $self->assert_archive_not_duplicate($author, $archive);

    # Assemble the basic structure...
    my $dist_struct = { author   => $author,
                        source   => $source,
                        archive  => $archive->basename,
                        mtime    => Pinto::Util::mtime($archive),
                        md5      => Pinto::Util::md5($archive),
                        sha256   => Pinto::Util::sha256($archive) };

    my $extractor = Pinto::PackageExtractor->new( archive => $archive );
    
    # Add provided packages...
    my @provides = $extractor->provides;
    $dist_struct->{packages} = \@provides;

    # Add required packages...
    my @requires = $extractor->requires;
    $dist_struct->{prerequisites} = \@requires;

    my $p = scalar @provides;
    my $r = scalar @requires;
    debug "Distribution $archive provides $p and requires $r packages";

    # Update database *before* moving the archive into the
    # repository, so if there is an error in the DB, we can stop and
    # the repository will still be clean.

    my $dist = $self->db->schema->create_distribution($dist_struct);
    $self->store->add_archive($archive => $dist->native_path);

    return $dist;
}

#------------------------------------------------------------------------------

=method fetch_distribution( url => $url )

Fetches a distribution archive from a remote URL and adds it to this
repository.  The packages provided by the distribution will be
indexed, and the prerequisites will be recorded.  Returns a
L<Pinto::Schema::Result::Distribution> object representing the fetched 
distribution.

=cut

sub fetch_distribution {
    my ($self, %args) = @_;

    my $url = $args{url};
    my $path = $url->path;

    my $existing = $self->get_distribution(path => $path);
    throw "Distribution $existing already exists" if $existing;

    my ($author, undef) = Pinto::Util::parse_dist_path($path);
    my $archive = $self->fetch_temporary(url => $url);

    my $dist = $self->add_distribution( archive   => $archive,
                                        author    => $author,
                                        source    => $url );
    return $dist;
}

#------------------------------------------------------------------------------

sub delete_distribution {
    my ($self, %args) = @_;

    my $dist  = $args{dist};
    my $force = $args{force};

    for my $reg ($dist->registrations) {
        # TODO: say which stack it is pinned to
        throw "$dist is pinned to a stack and cannot be deleted" 
            if $reg->is_pinned and not $force;
    }

    $dist->delete;
    my $basedir = $self->config->authors_id_dir;
    $self->store->remove_archive($dist->native_path($basedir));

    return $self;
}

#------------------------------------------------------------------------------

sub package_count {
    my ($self) = @_;

    return $self->db->schema->package_rs->count;
}

#-------------------------------------------------------------------------------

sub distribution_count {
    my ($self) = @_;

    return $self->db->schema->distribution_rs->count;
}

#-------------------------------------------------------------------------------

sub stack_count {
    my ($self) = @_;

    return $self->db->schema->stack_rs->count;
}

#-------------------------------------------------------------------------------

sub revision_count {
    my ($self) = @_;

    return $self->db->schema->revision_rs->count;
}

#-------------------------------------------------------------------------------

sub txn_begin {
    my ($self) = @_;

    debug 'Beginning db transaction';
    $self->db->schema->txn_begin;

    return $self;
}

#-------------------------------------------------------------------------------

sub txn_rollback {
    my ($self) = @_;

    debug 'Rolling back db transaction';
    $self->db->schema->txn_rollback;

    return $self;
}

#-------------------------------------------------------------------------------

sub txn_commit {
    my ($self) = @_;

    debug 'Committing db transaction';
    $self->db->schema->txn_commit;

    return $self;
}

#-------------------------------------------------------------------------------

sub svp_begin {
    my ($self, $name) = @_;

    debug 'Beginning db savepoint';
    $self->db->schema->svp_begin($name);

    return $self;
}

#-------------------------------------------------------------------------------

sub svp_rollback {
    my ($self, $name) = @_;

    debug 'Rolling back db savepoint';
    $self->db->schema->svp_rollback($name);

    return $self;
}

#-------------------------------------------------------------------------------
sub svp_release {
    my ($self, $name) = @_;

    debug 'Releasing db savepoint';
    $self->db->schema->svp_release($name);

    return $self;

}

#-------------------------------------------------------------------------------

sub create_stack {
    my ($self, %args) = @_;

    my $stk_name = $args{name};

    throw "Stack $stk_name already exists"
      if $self->get_stack($stk_name, nocroak => 1);

    my $root  = $self->db->get_root_revision;
    my $stack = $self->db->schema->create_stack( {%args, head => $root} );

    $stack->make_filesystem;
    $stack->write_index;

    return $stack;
}

#-------------------------------------------------------------------------------

sub copy_stack {
    my ($self, %args) = @_;

    my $copy_name  = $args{name};
    my $stack      = delete $args{stack};
    my $orig_name  = $stack->name;

    if (my $existing = $self->get_stack($copy_name, nocroak => 1) ) {
        throw "Stack $existing already exists"
    } 

    my $dupe = $stack->duplicate(%args);
    
    $dupe->make_filesystem;
    $dupe->write_index;

    return $dupe;
}

#-------------------------------------------------------------------------------

sub rename_stack {
    my ($self, %args) = @_;

    my $new_name = $args{to};
    my $stack    = delete $args{stack};
    my $old_name = $stack->name;

    throw "Stack $new_name already exists"
      if $self->get_stack($new_name, nocroak => 1);

    $stack->rename_filesystem(to => $new_name);
    $stack->rename(to => $new_name);

    return $stack;
}

#-------------------------------------------------------------------------------

sub kill_stack {
    my ($self, %args) = @_;

    my $stack = $args{stack};

    $stack->kill;
    $stack->kill_filesystem;

    return $stack;
}

#-------------------------------------------------------------------------------

sub link_modules_dir {
    my ($self, %args) = @_;

    my $target_dir  = $args{to};
    my $modules_dir = $self->config->modules_dir;
    my $root_dir    = $self->config->root_dir;

    if (-e $modules_dir or -l $modules_dir) {
        debug "Unlinking $modules_dir";
        unlink $modules_dir or throw $!;
    }

    debug "Linking $modules_dir to $target_dir";
    mksymlink($modules_dir => $target_dir->relative($root_dir));

    return $self;
}

#-------------------------------------------------------------------------------

sub unlink_modules_dir {
    my ($self) = @_;

    my $modules_dir = $self->config->modules_dir;

    if (-e $modules_dir or -l $modules_dir) {
        debug "Unlinking $modules_dir";
        unlink $modules_dir or throw $!;
    }

    return $self;
}

#-------------------------------------------------------------------------------

=method clean_files()

Deletes all distribution archives that are on the filesystem but not
in the database.  This can happen when an Action fails or is aborted
prematurely.

=cut

sub clean_files {
    my ($self, %args) = @_;

    my $deleted  = 0;
    my $dists_rs = $self->db->schema->distribution_rs->search(undef, {prefetch => {}});
    my %known_dists = map { ($_->to_string => 1) } $dists_rs->all;

    my $callback = sub {
        return if not -f $_;

        my $path    = Path::Class::file($_);
        my $author  = $path->parent->basename;
        my $archive = $path->basename;

        return if $archive eq 'CHECKSUMS';
        return if $archive eq '01mailrc.txt.gz';
        return if exists $known_dists{"$author/$archive"};

        debug "Removing orphaned archive at $path";
        $self->store->remove_archive($path);
        $deleted++;
    };

    my $authors_dir = $self->config->authors_dir;
    debug "Cleaning orphaned archives beneath $authors_dir";
    File::Find::find({no_chdir => 1, wanted => $callback}, $authors_dir);

    return $deleted;
}

#-------------------------------------------------------------------------------

sub optimize_database {
    my ($self) = @_;

    debug 'Removing empty database pages';
    $self->db->schema->storage->dbh->do('VACUUM;');

    debug 'Updating database statistics';
    $self->db->schema->storage->dbh->do('ANALYZE;');

    return $self;

}

#-------------------------------------------------------------------------------

sub get_version {
    my ($self) = @_;

    my $version_file = $self->config->version_file;

    return undef if not -e $version_file;  # Old repos have no version file

    my $version = $version_file->slurp(chomp => 1);

    return $version;
}

#-------------------------------------------------------------------------------

sub set_version {
    my ($self, $version) = @_;

    $version ||= $REPOSITORY_VERSION;

    my $version_fh = $self->config->version_file->openw;
    print { $version_fh } $version, "\n";
    close $version_fh;

    return $self;
}

#------------------------------------------------------------------------------

sub assert_archive_not_duplicate {
    my ($self, $author, $archive) = @_;

    throw "Archive $archive does not exist"  if not -e $archive;
    throw "Archive $archive is not readable" if not -r $archive;

    my $basename = $archive->basename;
    if (my $same_path = $self->get_distribution(author => $author, archive => $basename)) {
        throw "A distribution already exists as $same_path";
    }

    my $sha256 = Pinto::Util::sha256($archive);
    if (my $same_sha = $self->get_distribution(sha256 => $sha256)) {
        throw "Archive $archive is identical to $same_sha" unless $ENV{PINTO_ALLOW_DUPLICATES};
    }

    return;
}

#-------------------------------------------------------------------------------

sub assert_version_ok {
    my ($self) = @_;

    my $repo_version = $self->get_version;
    my $code_version = $REPOSITORY_VERSION;

    no warnings qw(uninitialized);
    if ($repo_version != $code_version) {
        my $msg = "Repository version ($repo_version) and Pinto version ($code_version) do not match.\n";

        # For really old repositories, the version is undefined and there is no automated
        # migration process.  If the version is defined, then automatic migration should work.
        
        $msg .= defined $repo_version ? "Use the 'migrate' command to bring the repo up to date"
                                      : "Contact thaljef\@cpan.org for migration instructions";
        throw $msg;
    }

    return;
}

#-------------------------------------------------------------------------------

sub assert_sanity_ok {
    my ($self) = @_;

    unless (    -e $self->config->db_file
             && -e $self->config->authors_dir ) {

        my $root_dir = $self->config->root_dir;
        throw "Directory $root_dir does not look like a Pinto repository";
    }

    return;
}

#-------------------------------------------------------------------------------

sub clear_cache {
    my ($self) = @_;

    $self->cache->clear_cache; # Clears cache file from disk
    $self->_clear_cache;       # Clears object from memory

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
