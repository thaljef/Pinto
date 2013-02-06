# ABSTRACT: Coordinates the database, files, and indexes

package Pinto::Repository;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Readonly;
use File::Find;
use Path::Class;

use Pinto::VCS;
use Pinto::Util;
use Pinto::Store;
use Pinto::Locker;
use Pinto::Database;
use Pinto::IndexCache;
use Pinto::PackageExtractor;
use Pinto::PrerequisiteWalker;
use Pinto::Exception qw(throw);

use version;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

Readonly::Scalar our $REPOSITORY_VERSION => 1;

#-------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable
         Pinto::Role::FileFetcher );

#-------------------------------------------------------------------------------

=attr db

=cut

has db => (
    is         => 'ro',
    isa        => 'Pinto::Database',
    lazy       => 1,
    default    => sub { Pinto::Database->new( config => $_[0]->config,
                                              logger => $_[0]->logger,
                                              repo   => $_[0] ) },
);

=attr store

=cut

has store => (
    is         => 'ro',
    isa        => 'Pinto::Store',
    lazy       => 1,
    default    => sub { Pinto::Store->new( config => $_[0]->config,
                                           logger => $_[0]->logger ) },
);

=attr vcs

=cut

has vcs => (
    is         => 'ro',
    isa        => 'Pinto::VCS',
    lazy       => 1,
    default    => sub { Pinto::VCS->new( config => $_[0]->config,
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
    handles    => [ qw(locate clear_cache) ],
    default    => sub { Pinto::IndexCache->new( config => $_[0]->config,
                                                logger => $_[0]->logger ) },
);

=attr locker

=method lock( $LOCK_TYPE )

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

    return $stack if Pinto::Util::itis($stack, 'Pinto::Schema::Result::Stack');
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

=method stack_count()

Returns the total number of stacks that currently exist in the repository.

=cut

sub stack_count {
    my ($self) = @_;

    return $self->db->schema->stack_rs->count;
}

#-------------------------------------------------------------------------------

=method get_package( name => $pkg_name )

Returns a L<Pinto:Schema::Result::Package> representing the latest
version of the package with the given C<$pkg_name>.  If there is no
such package with that name in the repository, returns nothing.

=method get_package( name => $pkg_name, path => $dist_path )

Returns the L<Pinto:Schema::Result::Package> with the given
C<$pkg_name> that belongs to the distribution identified by 
C<$dist_path>. If there is no such package in the repository, 
returns nothing.

=cut

sub get_package {
    my ($self, %args) = @_;

    my $pkg_name  = $args{name}; # Required
    my $dist_path = $args{path}; # Optional

    if ($dist_path) {

        my ($author, $archive) = Pinto::Util::parse_dist_path($dist_path);

        my $where = { 'me.name'              => $pkg_name, 
                      'distribution.author'  => $author,
                      'distribution.archive' => $archive };

        my @pkgs = $self->db->schema->search_package($where)->with_distribution;

        # TODO: Assert there is only one package
        return @pkgs ? $pkgs[0] : ();
    }
    else {
        my $where  = { name => $pkg_name };
        my @pkgs   = $self->db->schema->search_package($where)->with_distribution;

        my $latest = (sort {$a <=> $b} @pkgs)[-1];
        return defined $latest ? $latest : ();
    }
}

#-------------------------------------------------------------------------------

=method get_distribution( author => $author, archive => $archive )

=method get_distribution( spec => $dist_spec )

=method get_distribution( path => $dist_path )

=method get_distribution( sha256 => $sha256 )

Returns the L<Pinto::Schema::Result::Distribution> with the given
author ID and archive name.  If given a L<Pinto::DistributionSpec>
object, it will get the author ID and archive name from it instead.
If given a distribution path like those from an 02packages file, it
parses the author ID and archive name from that instead.  If there is
no matching distribution in the respoistory, returns nothing.

=cut

sub get_distribution {
    my ($self, %args) = @_;

    my %where;
    my %attrs;

    if (my $spec = $args{spec}) {
        my $author  = $spec->author_canonical;
        my $archive = $spec->archive;
        return $self->db->schema->distribution_rs
                                ->with_packages
                                ->find_by_author_archive($author, $archive);
    }
    elsif (my $path = $args{path}) {
        my ($author, $archive)   = Pinto::Util::parse_dist_path($path);
        return $self->db->schema->distribution_rs
                                ->with_packages
                                ->find_by_author_archive($author, $archive);
    }
    elsif (my $sha256 = $args{sha256}) {
         return $self->db->schema->distribution_rs
                                 ->with_packages
                                 ->find_by_sha256($sha256);

    }
    elsif (my $md5 = $args{md5}) {
         return $self->db->schema->distribution_rs
                                 ->with_packages
                                 ->find_by_md5($md5);
    }
    elsif (my $author = $args{author}) {
        my $archive = $args{archive} or throw "Must specify archive with author";
        return $self->db->schema->distribution_rs
                                ->with_packages
                                ->find_by_author_archive($author, $archive);
    }
    else {
        %where = %args;
    }

    return $self->db->schema->distribution_rs
                            ->with_packages
                            ->find( \%where, \%attrs );

}

#-------------------------------------------------------------------------------

sub get_distribution_by_spec {
    my ($self, %args) = @_;

    my $spec  = $args{spec};

    if ( Pinto::Util::itis($spec, 'Pinto::PackageSpec') ) {
        my $pkg_name = $spec->name;
        my $stack    = $args{stack} or throw "Must specify a stack";
        my $entry    = $stack->lookup(package => $pkg_name);
        throw "Package $pkg_name is not on stack $stack" if not defined $entry;

        my $dist_path = $entry->distribution;
        my $pkg       = $self->get_package(name => $pkg_name, path => $dist_path);
        throw "Package $pkg_name is on stack $stack but not in reposotiry" if not $pkg;

        return $pkg->distribution;
    }


    if ( Pinto::Util::itis($spec, 'Pinto::DistributionSpec') ) {
        my $dist = $self->get_distribution(spec => $spec);
        throw "Distribution $spec is not in the repository" if not $dist;

        return $dist;
    }


    my $type = ref $spec;
    throw "Don't know how to resolve target of type $type";
}

#-------------------------------------------------------------------------------

sub get_commit {
    my ($self, $commit_id) = @_;

    return $self->vcs->get_commit(commit_id => $commit_id);
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

    $self->_validate_archive($author, $archive);

    # Assemble the basic structure...
    my $dist_struct = { author   => $author,
                        source   => $source,
                        archive  => $archive->basename,
                        mtime    => Pinto::Util::mtime($archive),
                        md5      => Pinto::Util::md5($archive),
                        sha256   => Pinto::Util::sha256($archive) };

    my $extractor = Pinto::PackageExtractor->new( logger  => $self->logger,
                                                  archive => $archive );
    # Add provided packages...
    my @provides = $extractor->provides;
    $dist_struct->{packages} = \@provides;

    # Add required packages...
    my @requires = $extractor->requires;
    $dist_struct->{prerequisites} = \@requires;

    my $p = scalar @provides;
    my $r = scalar @requires;
    $self->info("Distribution $archive provides $p and requires $r packages");

    # Always update database *before* moving the archive into the
    # repository, so if there is an error in the DB, we can stop and
    # the repository will still be clean.

    my $dist = $self->db->schema->create_distribution( $dist_struct );
    my $basedir = $self->config->authors_id_dir;
    my $destination = $dist->native_path( $basedir );
    $self->store->add_archive( $archive => $destination );

    return $dist;
}

#------------------------------------------------------------------------------

sub delete { }

#------------------------------------------------------------------------------

sub _validate_archive {
    my ($self, $author, $archive) = @_;

    throw "Archive $archive does not exist"  if not -e $archive;
    throw "Archive $archive is not readable" if not -r $archive;

    my $basename = $archive->basename;
    if (my $same_path = $self->get_distribution(author => $author, archive => $basename)) {
        throw "A distribution already exists as $same_path";
    }

    my $sha256 = Pinto::Util::sha256($archive);
    if (my $same_sha = $self->get_distribution(sha256 => $sha256)) {
        throw "Archive $archive is identical to $same_sha";
    }

    return;
}

#------------------------------------------------------------------------------

=method pull( url => $url )

Pulls a distribution archive from a remote URL and adds it to this
repository.  The packages provided by the distribution will be
indexed, and the prerequisites will be recorded.  Returns a
L<Pinto::Schema::Result::Distribution> object representing the newly
pulled distribution.

=cut

sub pull {
    my ($self, %args) = @_;

    my $url = $args{url};
    my $path = $url->path;

    my $existing = $self->get_distribution(path => $path);
    throw "Distribution $existing already exists" if $existing;

    my ($author, undef) = Pinto::Util::parse_dist_path($path);
    my $archive = $self->fetch_temporary(url => $url);

    my $dist = $self->add( archive   => $archive,
                           author    => $author,
                           source    => $url );
    return $dist;
}

#------------------------------------------------------------------------------

sub find_or_pull {
    my ($self, %args) = @_;

    my $target = $args{target};
    my $stack  = $args{stack};

    if ( Pinto::Util::itis($target, 'Pinto::PackageSpec') ){
        return $self->_find_or_pull_by_package_spec($target, $stack);
    }
    elsif ( Pinto::Util::itis($target, 'Pinto::DistributionSpec') ){
        return $self->_find_or_pull_by_distribution_spec($target);
    }
    else {
        my $type = ref $target;
        throw "Don't know how to pull a $type";
    }
}

#------------------------------------------------------------------------------

sub _find_or_pull_by_package_spec {
    my ($self, $pspec, $stack) = @_;

    $self->info("Looking for package $pspec");
    my ($pkg_name, $pkg_ver) = ($pspec->name, $pspec->version);

    my $latest_in_stack = $stack->registry->lookup(package => $pkg_name);
    if (defined $latest_in_stack && $latest_in_stack->version >= $pkg_ver) {
        my $got_dist = $self->get_distribution(path => $latest_in_stack->path);
        $self->debug( sub {"Stack $stack already has package $pspec or newer as $latest_in_stack"} );
        return $got_dist;
    }


    my $latest_in_repo = $self->get_package(name => $pkg_name);
    if (defined $latest_in_repo && ($latest_in_repo->version >= $pkg_ver)) {
        my $got_dist = $latest_in_repo->distribution;
        $self->debug( sub {"Repository already has package $pspec or newer as $latest_in_repo"} );
        return $got_dist;
    }

    my $dist_url = $self->locate( package => $pspec->name,
                                  version => $pspec->version,
                                  latest  => 1 );

    throw "Cannot find prerequisite $pspec anywhere"
      if not $dist_url;

    $self->debug("Found package $pspec or newer in $dist_url");

    if ( Pinto::Util::isa_perl($dist_url) ) {
        $self->debug("Distribution $dist_url is a perl. Skipping it");
        return;
    }

    $self->notice("Pulling distribution $dist_url");
    my $pulled_dist = $self->pull(url => $dist_url);

    return $pulled_dist;
}

#------------------------------------------------------------------------------

sub _find_or_pull_by_distribution_spec {
    my ($self, $dspec) = @_;

    $self->info("Looking for distribution $dspec");

    my $got_dist = $self->get_distribution( spec => $dspec );

    if ($got_dist) {
        $self->info("Already have distribution $dspec");
        return $got_dist;
    }

    my $dist_url = $self->locate(distribution => $dspec->path)
      or throw "Cannot find prerequisite $dspec anywhere";

    $self->debug("Found package $dspec at $dist_url");

    if ( Pinto::Util::isa_perl($dist_url) ) {
        $self->debug("Distribution $dist_url is a perl. Skipping it");
        return;
    }

    $self->notice("Pulling distribution $dist_url");
    my $pulled_dist = $self->pull(url => $dist_url);

    return $pulled_dist;
}

#------------------------------------------------------------------------------

sub pull_prerequisites {
    my ($self, %args) = @_;

    my $dist  = $args{dist};
    my $stack = $args{stack};

    my $cb = sub {
        my ($walker, $prereq) = @_;
        my $dist = $self->find_or_pull(target => $prereq, stack => $stack) or return;
        $stack->register(distribution => $dist);
        return $dist;
    };

    my $walker = Pinto::PrerequisiteWalker->new(start => $dist, callback => $cb);
    $walker->walk;

    return $self;
}

#-------------------------------------------------------------------------------

sub create_stack {
    my ($self, %args) = @_;

    my $stk_name = $args{name};

    throw "Stack $stk_name already exists"
      if $self->get_stack($stk_name, nocroak => 1);

    my $stack = $self->db->schema->create_stack(\%args);

    $self->vcs->checkout_branch(name => $stack->name, as_orphan => 1);
    $self->commit(stack => $stack, as_orphan => 1);

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

    my $copy = $stack->copy(%args)->finalize;
    $self->vcs->fork_branch(from => $orig_name, to => $copy_name);

    return $copy;
}

#-------------------------------------------------------------------------------

sub rename_stack {
    my ($self, %args) = @_;

    my $new_name = $args{to};
    my $stack    = delete $args{stack};
    my $old_name = $stack->name;

    throw "Stack $new_name already exists"
      if $self->get_stack($new_name, nocroak => 1);

    $stack->rename(to => $new_name);
    $self->vcs->rename_branch(from => $old_name, to => $new_name);

    return $stack;
}

#-------------------------------------------------------------------------------

sub kill_stack {
    my ($self, %args) = @_;

    my $stack = $args{stack};

    $stack->kill;
    $self->vcs->delete_branch(branch => $stack->name);

    return $stack;
}

#-------------------------------------------------------------------------------

sub commit {
    my ($self, %args) = @_;

    my $stack       = delete $args{stack};
    my %commit_args = %args;

    $stack->write_index;
    $stack->write_registry;

    my $reg_file = $stack->registry_file;
    $self->vcs->checkout_branch(name => $stack->name) unless $args{as_orphan};
    $self->vcs->add(file => $reg_file->basename, from => $reg_file);

    # NOTE: Git will create a commit object even if nothing has changed.  The new commit
    # will just point to the same tree as the last commit.  So it is up to you to check
    # whether you really need to commit or not.  Use $stack->stack_has_changed().

    my $commit_id = $self->vcs->commit(%commit_args);
    $stack->update( {last_commit_id => $commit_id} );

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

        $self->info("Removing orphaned archive at $path");
        $self->store->remove_archive($path);
        $deleted++;
    };

    my $authors_dir = $self->config->authors_dir;
    $self->notice("Cleaning orphaned archives beneath $authors_dir");
    File::Find::find({no_chdir => 1, wanted => $callback}, $authors_dir);

    return $deleted;
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

#-------------------------------------------------------------------------------

sub assert_version_ok {
    my ($self) = @_;

    my $repo_version = $self->get_version;
    my $code_version = $REPOSITORY_VERSION;

    throw "Repository version ($repo_version) and Pinto version ($code_version) do not match"
        if $repo_version != $code_version;

    return $self;
}

#-------------------------------------------------------------------------------

sub assert_sanity_ok {
    my ($self) = @_;

    unless (    -e $self->config->db_file
             && -e $self->config->version_file
             && -e $self->config->modules_dir
             && -e $self->config->authors_dir ) {

        my $root_dir = $self->config->root_dir;
        throw "Directory $root_dir does not look like a Pinto repository";
    }

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
