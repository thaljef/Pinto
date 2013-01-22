# ABSTRACT: Coordinates the database, files, and indexes

package Pinto::Repository;

use Moose;

use Path::Class;
use File::Find;
use File::Copy qw(move);

use Pinto::VCS;
use Pinto::Util;
use Pinto::Store;
use Pinto::Locker;
use Pinto::Database;
use Pinto::IndexCache;
use Pinto::PackageExtractor;
use Pinto::Exception qw(throw);
use Pinto::Util qw(itis);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

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
    handles    => [ qw(locate) ],
    clearer    => 'clear_cache',
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

sub BUILD {
    my ($self) = @_;

    unless (    -e $self->config->db_dir
             && -e $self->config->modules_dir
             && -e $self->config->authors_dir ) {

        my $root_dir = $self->config->root_dir();
        throw "Directory $root_dir does not look like a Pinto repository";
    }

    return $self;
}

#-------------------------------------------------------------------------------

sub check_version {
    my ($self) = @_;

    my $schema_version = $self->db->schema->schema_version;
    my $db_version     = $self->db->schema->get_version;

    throw "Database version ($db_version) and schema version ($schema_version) do not match"
        if $db_version != $schema_version;

    return $self;
}

#-------------------------------------------------------------------------------


sub get_property {
    my ($self, @keys) = @_;

    my %props = %{ $self->get_properties };
    return @props{@keys};
}

#-------------------------------------------------------------------------------

sub get_properties {
    my ($self) = @_;

    my @props = $self->db->repository_properties->search->all;

    return { map { $_->key => $_->value } @props };
}

#-------------------------------------------------------------------------------

sub set_property {
    my ($self, $key, $value) = @_;

    return $self->set_properties( {$key => $value} );
}

#-------------------------------------------------------------------------------

sub set_properties {
    my ($self, $props) = @_;

    my $attrs  = {key => 'key_canonical_unique'};
    while (my ($key, $value) = each %{$props}) {
        Pinto::Util::validate_property_name($key);
        my $kv_pair = {key => $key, key_canonical => lc($key), value => $value};
        $self->db->repository_properties->update_or_create($kv_pair, $attrs);
    }

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_property {
    my ($self, @keys) = @_;

    for my $key (@keys) {
        my $where = {key => $key};
        my $prop = $self->db->repository_properties->update_or_create($where);
        $prop->delete if $prop;
    }

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_properties {
    my ($self) = @_;

    # TODO: Do not allow deletion of system props
    my $props_rs = $self->db->repository_properties->search;
    $props_rs->delete;

    return $self;
}

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
    my @stacks = $self->db->select_stacks( $where )->all;

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

    return $self->db->select_stacks->all;
}

#-------------------------------------------------------------------------------

=method get_package( name => $pkg_name )

Returns a L<Pinto:Schema::Result::Package> representing the latest
version of the package with the given C<$pkg_name>.  If there is no
such package with that name in the repository, returns nothing.

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
        my $kommit = $self->get_stack($stk_name)->head;
        my $where  = { 'package.name' => $pkg_name, kommit => $kommit->id };
        my $registration = $self->db->select_registration($where);
        return $registration ? $registration->package : ();
    }
    else {
        my $where  = { name => $pkg_name };
        my @pkgs   = $self->db->select_packages( $where )->all;
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
    my %attrs = (key => 'author_canonical_archive_unique');

    if (my $spec = $args{spec}) {
        $where{author_canonical} = $spec->author_canonical;
        $where{archive}          = $spec->archive;
    }
    elsif (my $path = $args{path}) {
        my ($author, $archive)    = Pinto::Util::parse_dist_path($path);
        $where{author_canonical}  = uc $author;
        $where{archive}           = $archive;
    }
    elsif (my $sha256 = $args{sha256}){
         $where{sha256} = $sha256;
         $attrs{key} = 'sha256_unique';
    }
    elsif (my $md5 = $args{md5}){
         $where{md5} = $md5;
         $attrs{key} = 'md5_unique';
    }
    else {
        %attrs = ();
        %where = %args;
    }

    return $self->db->select_distribution( \%where, \%attrs );

}

#-------------------------------------------------------------------------------

sub get_distribution_by_spec {
    my ($self, %args) = @_;

    my $spec  = $args{spec};

    if ( itis($spec, 'Pinto::PackageSpec') ) {
        my $pkg_name = $spec->name;
        my $stack    = $args{stack} or throw "Must specify a stack";
        my $pkg      = $self->get_package(name => $pkg_name, stack => $stack);
        throw "Package $pkg_name is not on stack $stack" if not $pkg;

        return $pkg->distribution;
    }


    if ( itis($spec, 'Pinto::DistributionSpec') ) {
        my $author  = $spec->author;
        my $archive = $spec->archive;
        my $dist = $self->get_distribution(spec => $spec);
        throw "Distribution $spec does not exist" if not $dist;

        return $dist;
    }


    my $type = ref $spec;
    throw "Don't know how to resolve target of type $type";
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

sub delete {
    my ($self, %args) = @_;

    my $dist  = $args{dist};
    my $force = $args{force};

    throw "Cannot delete $dist because it has packages that are pinned"
        if !$force && grep {$_->is_pinned} $dist->registrations;

    $dist->delete;

    my $basedir = $self->config->authors_id_dir;
    my $path = $dist->native_path( $basedir );
    $self->store->remove_archive( $path );

    return $dist;
}

#------------------------------------------------------------------------------

sub _validate_archive {
    my ($self, $author, $archive) = @_;

    throw "Archive $archive does not exist"  if not -e $archive;
    throw "Archive $archive is not readable" if not -r $archive;

    my $basename = $archive->basename;
    if (my $same_path = $self->get_distribution(author_canonical => uc($author), archive => $basename)) {
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

    if ( itis($target, 'Pinto::PackageSpec') ){
        return $self->_find_or_pull_by_package_spec($target, $stack);
    }
    elsif ( itis($target, 'Pinto::DistributionSpec') ){
        return $self->_find_or_pull_by_distribution_spec($target, $stack);
    }
    else {
        my $type = ref $target;
        throw "Don't know how to pull a $type";
    }
}

#------------------------------------------------------------------------------

sub _find_or_pull_by_package_spec {
    my ($self, $pspec, $stack) = @_;

    $DB::single = 1;
    $self->info("Looking for package $pspec");
    my ($pkg_name, $pkg_ver) = ($pspec->name, $pspec->version);


    my $latest_in_stack = $stack->registration(package => $pspec);
    if (defined $latest_in_stack && $latest_in_stack->package->version >= $pkg_ver) {
        my $got_dist = $latest_in_stack->package->distribution;
        $self->debug( sub {"Stack $stack already has package $pspec or newer as $latest_in_stack"} );
        return ($got_dist, 0);
    }


    my $latest_in_repo = $self->get_package(name => $pkg_name);
    if (defined $latest_in_repo && ($latest_in_repo->version >= $pkg_ver)) {
        my $got_dist = $latest_in_repo->distribution;
        $self->debug( sub {"Repository already has package $pspec or newer as $latest_in_repo"} );
        return ($got_dist, 0);
    }

    my $dist_url = $self->locate( package => $pspec->name,
                                  version => $pspec->version,
                                  latest  => 1 );

    throw "Cannot find prerequisite $pspec anywhere"
      if not $dist_url;

    $self->debug("Found package $pspec or newer in $dist_url");

    if ( Pinto::Util::isa_perl($dist_url) ) {
        $self->debug("Distribution $dist_url is a perl. Skipping it");
        return (undef, 0);
    }

    $self->notice("Pulling distribution $dist_url");
    my $pulled_dist = $self->pull(url => $dist_url);

    return ($pulled_dist, 1);
}

#------------------------------------------------------------------------------

sub _find_or_pull_by_distribution_spec {
    my ($self, $dspec) = @_;

    $self->info("Looking for distribution $dspec");

    my $got_dist = $self->get_distribution( spec => $dspec );

    if ($got_dist) {
        $self->info("Already have distribution $dspec");
        return ($got_dist, 0);
    }

    my $dist_url = $self->locate(distribution => $dspec->path)
      or throw "Cannot find prerequisite $dspec anywhere";

    $self->debug("Found package $dspec at $dist_url");

    if ( Pinto::Util::isa_perl($dist_url) ) {
        $self->debug("Distribution $dist_url is a perl. Skipping it");
        return (undef, 0);
    }

    $self->notice("Pulling distribution $dist_url");
    my $pulled_dist = $self->pull(url => $dist_url);

    return ($pulled_dist, 1);
}

#------------------------------------------------------------------------------

sub pull_prerequisites {
    my ($self, %args) = @_;

    my $dist  = $args{dist};
    my $stack = $args{stack};

    my @prereq_queue = $dist->prerequisite_specs;
    my %visited = ($dist->path => 1);
    my @pulled;
    my %seen;

  PREREQ:
    while (my $prereq = shift @prereq_queue) {

        my ($required_dist, $did_pull) = $self->find_or_pull(target => $prereq, stack => $stack);
        next PREREQ if not $required_dist;

        my $did_register = $required_dist->register(stack => $stack);

        push @pulled, $required_dist if $did_pull || $did_register;

        if ( $visited{$required_dist->path} ) {
            # We don't need to recurse into prereqs more than once
            $self->debug("Already visited archive $required_dist");
            next PREREQ;
        }

      NEW_PREREQ:
        for my $new_prereq ( $required_dist->prerequisite_specs ) {

            # This is all pretty hacky.  It might be better to represent the queue
            # as a hash table instead of a list, since we really need to keep track
            # of things by name.

            # Add this prereq to the queue only if greater than the ones we already got
            my $name = $new_prereq->{name};

            next NEW_PREREQ if exists $seen{$name}
                               && $new_prereq->{version} <= $seen{$name};

            # Take any prior versions of this prereq out of the queue
            @prereq_queue = grep { $_->{name} ne $name } @prereq_queue;

            # Note that this is the latest version of this prereq we've seen so far
            $seen{$name} = $new_prereq->{version};

            # Push the prereq onto the queue
            push @prereq_queue, $new_prereq;
        }

        $visited{$required_dist->path} = 1;
    }

    return @pulled;
}

#-------------------------------------------------------------------------------

=method create_stack(name => $stk_name)

=cut

sub create_stack {
    my ($self, %args) = @_;

    Pinto::Util::validate_stack_name($args{name});

    throw "Stack $args{name} already exists"
        if $self->get_stack($args{name}, nocroak => 1);

    my $stack = $self->db->schema->create_stack( \%args );

    return $stack;
}

#-------------------------------------------------------------------------------

sub copy_stack {
    my ($self, %args) = @_;

    my $from_stack    = $args{from};
    my $to_stack_name = $args{to};

    my $changes  = {name => $to_stack_name};
    my $copy     = $from_stack->copy( $changes );

    $self->create_stack_filesystem(stack => $copy);
    $copy->write_index;

    return $copy;
}

#-------------------------------------------------------------------------------

sub delete_stack_filesystem {
    my ($self, %args) = @_;

    my $stack = $args{stack};
    throw "Stack $self is locked and cannot be deleted" if $stack->is_locked;

    my $stack_dir = $self->root_dir->subdir($stack->name);
    $self->debug("Removing stack directory $stack_dir");

    $stack_dir->rmtree or throw "Failed to remove $stack_dir" if -e $stack_dir;

    return $self;
}

#-------------------------------------------------------------------------------

sub rename_stack_filesystem {
    my ($self, %args) = @_;

    my $from = $args{from};
    my $to   = $args{to};

    my $from_stack_dir = $self->root_dir->subdir($from);
    throw "Directory $from_stack_dir does not exist" if not -e $from_stack_dir;

    my $to_stack_dir   = $self->root_dir->subdir($to);
    throw "Directory $to_stack_dir already exists" if -e $to_stack_dir;

    $self->debug("Renaming $from_stack_dir to $to_stack_dir");
    move($from_stack_dir, $to_stack_dir) or throw "Rename failed: $!";

    return $self;
}

#-------------------------------------------------------------------------------

sub create_stack_vcs_branch {
    my ($self, %args) = @_;

    my $from = $args{from_stack}->name;
    my $to   = $args{to_stack}->name;
    my $vcs = $self->vcs;

    $vcs->branch($from, $to);
    $vcs->checkout($to);

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
    my $dists_rs = $self->db->select_distributions(undef, {prefetch => {}});
    my %known_dists = map { ($_->to_string => 1) } $dists_rs->all;

    my $callback = sub {
        return if not -f $_;

        my $path    = file($_);
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

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
