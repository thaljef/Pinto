package Pinto::Repository;

# ABSTRACT: Coordinates the database, files, and indexes

use Moose;

use Try::Tiny;
use Class::Load;

use Pinto::Database;
use Pinto::IndexCache;
use Pinto::Types qw(Dir);
use Pinto::Exceptions qw(throw_fatal throw_error);

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
    handles    => [ qw(write_index select_distributions select_packages) ],
    lazy_build => 1,
);


has store => (
    is         => 'ro',
    isa        => 'Pinto::Store',
    handles    => [ qw(initialize commit tag) ],
    lazy_build => 1,
);


has cache => (
    is         => 'ro',
    isa        => 'Pinto::IndexCache',
    lazy_build => 1,
);


has extractor => (
    is         => 'ro',
    isa        => 'Pinto::PackageExtractor',
    lazy_build => 1,
);

#-------------------------------------------------------------------------------

sub _build_db {
    my ($self) = @_;

    return Pinto::Database->new( config => $self->config(),
                                 logger => $self->logger() );
}

#-------------------------------------------------------------------------------

sub _build_store {
    my ($self) = @_;

    my $store_class = $self->config->store();

    try   { Class::Load::load_class( $store_class ) }
    catch { throw_fatal "Unable to load store class $store_class: $_" };

    return $store_class->new( config => $self->config(),
                              logger => $self->logger() );
}

#-------------------------------------------------------------------------------

sub _build_cache {
    my ($self) = @_;

    return Pinto::IndexCache->new( config => $self->config(),
                                   logger => $self->logger() );
}

#------------------------------------------------------------------------------

sub _build_extractor {
    my ($self) = @_;

    return Pinto::PackageExtractor->new( config => $self->config(),
                                         logger => $self->logger() );
}


#-------------------------------------------------------------------------------
# Methods

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

sub add_distribution {
    my ($self, %args) = @_;

    my $archive = $args{archive};
    my $author  = $args{author};
    my $source  = $args{source} || 'LOCAL';
    my $stack   = $args{stack}  || 'default';
    my $index   = $args{index}  || 1;
    my $pin     = $args{pin};

    throw_error "Archive $archive does not exist"  if not -e $archive;
    throw_error "Archive $archive is not readable" if not -r $archive;

    $stack = $self->get_stack(name => $stack)
        || throw_error qq{No such stack named "$stack"};

    $pin = $self->db->create_pin( {reason => $pin} )
        if $pin;

    my $basename   = $archive->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path  = $author_dir->file($basename)->as_foreign('Unix')->stringify();

    $self->get_distribution(path => $dist_path)
        and throw_error "Distribution $dist_path already exists";

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

    my $dist = $self->db->create_distribution( $dist_struct, $stack, $pin );
    my $repo_archive = $dist->archive( $self->root_dir() );
    $self->fetch( from => $archive, to => $repo_archive );
    $self->store->add_archive( $repo_archive );

    return $dist;
}

#------------------------------------------------------------------------------

sub mirror_distribution {
    my ($self, %args) = @_;

    my $struct = $args{struct};
    my $stack  = $args{stack};

    $stack = $self->get_stack(name => $stack)
        || throw_error qq{No such stack named "$stack"};

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


sub import_distribution {
    my ($self, %args) = @_;

    my $url   = $args{url};
    my $stack = $args{stack};

    my ($source, $path, $author) = Pinto::Util::parse_dist_url( $url );

    my $existing = $self->get_distribution( path => $path );
    throw_error "Distribution $path already exists" if $existing;

    my $archive = $self->fetch_temporary(url => $url);

    my $dist = $self->add_distribution( archive   => $archive,
                                        author    => $author,
                                        source    => $source,
                                        stack     => $stack );
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

sub register_distribution {
    my ($self, %args) = @_;

    my $dist  = $args{dist};
    my $stack = $args{stack};

    $stack = $self->get_stack(name => $stack)
        || throw_error "No such stack named $stack";

    $self->info("Registering distribution $dist on stack $stack");

    for my $pkg ( $dist->packages() ) {
        $self->db->register($pkg, $stack);
    }

    return $dist;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
