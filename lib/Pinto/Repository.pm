package Pinto::Repository;

# ABSTRACT: Coordinates the database, files, and indexes

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

has db => (
    is         => 'ro',
    isa        => 'Pinto::Database',
    lazy       => 1,
    handles    => [ qw(write_index select_distributions select_packages) ],
    default    => sub { Pinto::Database->new( config => $_[0]->config,
                                              logger => $_[0]->logger ) },
);


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


has cache => (
    is         => 'ro',
    isa        => 'Pinto::IndexCache',
    lazy       => 1,
    default    => sub { Pinto::IndexCache->new( config => $_[0]->config,
                                                logger => $_[0]->logger ) },
);


has locker  => (
    is         => 'ro',
    isa        => 'Pinto::Locker',
    lazy       => 1,
    handles    => [ qw(lock unlock) ],
    default    => sub { Pinto::Locker->new( config => $_[0]->config,
                                            logger => $_[0]->logger ) },
);


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

=method get_latest_package( name => $package_name )

Returns the latest version of L<Pinto:Schema::Result::Package> with
the given C<$package_name>.  If there is no such package with that
name in the repository, returns C<undef>.

=cut

sub get_latest_package {
    my ($self, %args) = @_;

    my $pkg_name = $args{name};

    my $where = { name => $pkg_name };
    my @packages = $self->db->select_packages( $where )->all();
    my $latest   = (sort {$a <=> $b} @packages)[-1];

    return $latest;
}

#-------------------------------------------------------------------------------

=method get_distribution( path => $dist_path )

Returns the L<Pinto::Schema::Result::Distribution> with the given
C<$dist_path>.  If there is no distribution with such a path in the
respoistory, returns C<undef>.  Note the C<$dist_path> is a Unix-style
path fragment that identifies the location of the distribution archive
within the repository, such as F<J/JE/JEFF/Pinto-0.033.tar.gz>

=cut

sub get_distribution {
    my ($self, %args) = @_;

    my $dist_path = $args{path};

    my $where = { path => $dist_path };
    my $attrs = { prefetch => 'packages' };
    my $dist  = $self->db->select_distributions( $where, $attrs )->first();

    return $dist;
}

#-------------------------------------------------------------------------------

=method get_stack( name => $stack_name )

Returns the L<Pinto::Schema::Result::Stack> object with the given
C<$stack_name>.  If there is no stack with such a name in the
repository, returns C<undef>.

=cut

sub get_stack {
   my ($self, %args) = @_;

    my $stack_name = $args{name};

    my $where = { name => $stack_name };
    my $stack  = $self->db->select_stacks( $where )->single();

    return $stack;
}

#-------------------------------------------------------------------------------

=method get_stack_member( package => $package_name, stack => $stack_name )

Returns the L<Pinto::Schema::Result::PackageStack> object with the
given C<$package_name> and C<$stack_name>.  If there is no
PackageStack with such names in the repository, returns C<undef>.  A
PackageStack represents the relationship between a Package and a
Stack.

=cut

sub get_stack_member {
    my ($self, %args) = @_;

    my $package_name = $args{package};
    my $stack_name   = $args{stack};

    my $where = { 'package.name' => $package_name,
                  'stack.name'   => $stack_name };

    my $attrs = { prefetch => [ qw(package stack) ] };

    my $pkg_stk = $self->db->select_package_stacks($where, $attrs)->single();

    return $pkg_stk;
}

#-------------------------------------------------------------------------------

sub add {
    my ($self, %args) = @_;

    my $archive = $args{archive};
    my $author  = $args{author};
    my $source  = $args{source} || 'LOCAL';
    my $index   = $args{index}  || 1;

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
# TODO: Maybe refactor this to use the add() method

sub mirror {
    my ($self, %args) = @_;

    my $struct = $args{struct};

    my $url = URI->new($struct->{source} . '/authors/id/' . $struct->{path});
    $self->info("Mirroring distribution at $url");

    my $temp_archive  = $self->fetch_temporary(url => $url);
    $struct->{mtime}  = Pinto::Util::mtime($temp_archive);
    $struct->{md5}    = Pinto::Util::md5($temp_archive);
    $struct->{sha256} = Pinto::Util::sha256($temp_archive);

    my $dist = $self->db->create_distribution($struct, $stack);

    my @path_parts = split m{ / }mx, $struct->{path};
    my $repo_archive = $self->root_dir->file( qw(authors id), @path_parts );
    $self->fetch(from => $temp_archive, to => $repo_archive);
    $self->store->add_archive($repo_archive);

    return $dist;
}

#------------------------------------------------------------------------------


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

sub remove_distribution {
    my ($self, %args) = @_;

    my $dist = $args{dist};

    my $count = $dist->package_count();
    $self->notice("Removing distribution $dist with $count packages");

    $self->db->delete_distribution($dist);

    $self->store->remove_archive( $dist->archive( $self->root_dir() ) );

    return $dist;
}

#-------------------------------------------------------------------------------

sub register {
    my ($self, %args) = @_;

    my $dist  = $args{distribution};
    my $pkg   = $args{package};
    my $stack = $args{stack};
    my $did_register = 0;

    if ($dist) {
        $self->info("Registering distribution $dist on stack $stack");
        $did_register += $self->db->register($_, $stack) for $dist->packages;
    }
    elsif ($pkg) {
        $self->info("Registering package $pkg on stack $stack");
        $did_register += $self->db->register($pkg, $stack);
    }

    return $did_register;
}

#-------------------------------------------------------------------------------

sub pin {
    my ($self, %args) = @_;

    my $dist   = $args{distribution};
    my $pkg    = $args{package};
    my $stack  = $args{stack};

    if ($dist) {
        $self->info("Pinning distribution $dist on stack $stack");
        $self->db->pin($_, $stack) for $dist->packages;
    }
    elsif ($pkg) {
        $self->info("Pinning package $pkg on stack $stack");
        $self->db->pin($pkg, $stack);
    }

    return $self;

}
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
