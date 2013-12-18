# ABSTRACT: Find a package among CPAN-like repositories

package Pinto::PackageLocator;

use Moose;
use MooseX::Types::Moose qw(ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Carp;
use File::Temp;
use LWP::UserAgent;
use URI;

use Pinto::Types qw(Uri Dir);
use Pinto::PackageLocator::Index;
use Pinto::PackageSpec;

use version;


#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

=attr repository_urls => [ qw(http://somewhere http://somewhere.else) ]

An array reference containing the base URLs of the repositories you
want to search.  These are usually CPAN mirrors, but can be any
website or local directory that is organized in a CPAN-like structure.
For each request, repositories are searched in the order you specified
them here.  This defaults to http://cpan.perl.org.

=cut

has repository_urls => (
    is         => 'ro',
    isa        => ArrayRef[Uri],
    auto_deref => 1,
    default    => sub { [URI->new('http://cpan.perl.org')] },
);

#------------------------------------------------------------------------------

=attr user_agent => $user_agent_obj

The L<LWP::UserAgent> object that will fetch index files.  If you do
not provide a user agent, then a default one will be constructed for
you.

=cut

has user_agent => (
   is          => 'ro',
   isa         => 'LWP::UserAgent',
   builder     => '_build_user_agent',
);

sub _build_user_agent {
    my ($self) = @_;

    my $agent = sprintf "%s/%s", ref $self, $self->VERSION || 'UNKNOWN';
    return LWP::UserAgent->new(agent => $agent, env_proxy => 1, keep_alive => 5);
}

#------------------------------------------------------------------------------

=attr cache_dir => '/some/directory/path'

The path (as a string or L<Path::Class::Dir> object) to a directory
where the index file will be cached.  If the directory does not exist,
it will be created for you.  If you do not specify a cache directory,
then a temporary directory will be used.  The temporary directory will
be deleted when your application terminates.

=cut

has cache_dir => (
   is         => 'ro',
   isa        => Dir,
   default    => sub { File::Temp::tempdir(CLEANUP => 1) },
   coerce     => 1,
);

#------------------------------------------------------------------------------

=attr force => $boolean

Causes any cached index files to be removed, thus forcing a new one to
be downloaded when the object is constructed.  This only has effect if
you specified the C<cache_dir> attribute.  The default is false.

=cut

has force => (
   is         => 'ro',
   isa        => 'Bool',
   default    => 0,
);

#------------------------------------------------------------------------------

=method indexes()

Returns a list of L<Package::Locator::Index> objects representing the
indexes of each of the repositories.  The indexes are only populated
on-demand when the C<locate> method is called.  The order of the
indexes is the same as the order of the repositories defined by the
C<repository_urls> attribute.

=cut

has indexes => (
   is         => 'ro',
   isa        => 'ArrayRef[Pinto::PackageLocator::Index]',
   auto_deref => 1,
   lazy_build => 1,
   init_arg   => undef,
);


#------------------------------------------------------------------------------

sub _build_indexes {
    my ($self) = @_;

    my @indexes = map { Pinto::PackageLocator::Index->new( force          => $self->force(),
                                                      cache_dir      => $self->cache_dir(),
                                                      user_agent     => $self->user_agent(),
                                                      repository_url => $_ )
    } $self->repository_urls();

    return \@indexes;
}

#------------------------------------------------------------------------------

=method locate( package => 'Foo::Bar' )

=method locate( package => 'Foo::Bar', latest => 1 )

=method locate( package => 'Foo::Bar', version => '1.2')

=method locate( package => 'Foo::Bar', version => '1.2', latest => 1 )

=method locate ( distribution => 'A/AU/AUTHOR/Foo-Bar-1.0.tar.gz' )

Given the name of a package, searches all the repository indexes and
returns the URL to a distribution containing that requested package,
or the distribution you requested.

If you also specify a C<version>, then you'll always get a
distribution that contains that version of the package or higher.  If
you also specify C<latest> then you'll always get the distribution
that contains the latest version of the package that can be found in
all the indexes.  Otherwise you'll just get the first distribution we
can find that satisfies your request.

If you give a distribution path instead, then you'll just get back the
URL to the first distribution we find at that path in any of the
repository indexes.

If neither the package nor the distribution path can be found in any
of the indexes, returns undef.

=cut

sub locate {
    my ($self, %args) = @_;

    $self->_validate_locate_args(%args);

    if ($args{spec}) {
        my $spec   = $args{spec};
        my $latest = $args{latest} || 0;
        return $self->_locate_package($spec, $latest);
    }
    else {
        my $dist = $args{distribution};
        return $self->_locate_dist($dist);
    }
}

#------------------------------------------------------------------------------

sub _validate_locate_args {
    my ($self, %args) = @_;

    croak 'Cannot specify latest and distribution together'
        if $args{distribution} and $args{latest};

    croak 'Cannot specify spec and distribution together'
        if $args{distribution} and $args{spec};

    croak 'Must specify spec or distribution'
        if not ( $args{distribution} or $args{spec} );

    return 1;
}

#------------------------------------------------------------------------------

sub _locate_package {
    my ($self, $spec, $latest) = @_;

    $spec = Pinto::PackageSpec->new($spec) if not ref $spec;

    my ($latest_found_package, $found_in_index);
    for my $index ( $self->indexes() ) {

        my $found_package = $index->packages->{$spec->name};
        next if not $found_package;

        my $found_package_version = version->parse( $found_package->{version} );
        next if not $spec->is_satisfied_by($found_package_version);

        $found_in_index       ||= $index;
        $latest_found_package ||= $found_package;
        last unless $latest;

        ($found_in_index, $latest_found_package) = ($index, $found_package)
            if $self->__compare_packages($found_package, $latest_found_package) == 1;
    }


    if ($latest_found_package) {
        my $base_url = $found_in_index->repository_url();
        my $latest_dist_path = $latest_found_package->{distribution};
        return  URI->new( "$base_url/authors/id/" . $latest_dist_path );
    }

    return;
}

#------------------------------------------------------------------------------

sub _locate_dist {
    my ($self, $dist_path) = @_;

    for my $index ( $self->indexes ) {
        my $base_url = $index->repository_url();
        my $dist_url =  URI->new("$base_url/authors/id/$dist_path");

        return $dist_url if $index->distributions->{$dist_path};
        return $dist_url if $self->user_agent->head($dist_url)->is_success;
    }


    return;
}

#------------------------------------------------------------------------------

sub __compare_packages {
    my ($self, $pkg_a, $pkg_b) = @_;

    my $pkg_a_version = $self->__versionize( $pkg_a->{version} );
    my $pkg_b_version = $self->__versionize( $pkg_b->{version} );

    # TODO: compare dist mtimes (but they are on the server!)
    return  $pkg_a_version  <=> $pkg_b_version;
}

#------------------------------------------------------------------------------

sub __versionize {
    my ($self, $version) = @_;

    my $v = eval { version->parse($version) };

    return defined $v ? $v : version->new(0);
}

#------------------------------------------------------------------------------

=method clear_cache()

Deletes the cached index files.  Any subsequent calls to the C<locate>
method will cause the index files to be fetched anew.

=cut

sub clear_cache {
    my ($self) = @_;

    for my $index ( $self->indexes() ) {
        $index->index_file->remove();
    }

    $self->clear_indexes();

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  use Package::Locator;

  # Basic search...
  my $locator = Package::Locator->new();
  my $url = locator->locate( package => 'Test::More' );

  # Search for first within multiple repositories:
  my $repos = [ qw(http://cpan.pair.com http://my.company.com/DPAN) ];
  my $locator = Package::Locator->new( repository_urls => $repos );
  my $url = locator->locate( package => 'Test::More' );

  # Search for first where version >= 0.34:
  my $repos = [ qw(http://cpan.pair.com http://my.company.com/DPAN) ];
  my $locator = Package::Locator->new( repository_urls => $repos );
  my $url = locator->locate( package => 'Test::More' version => 0.34);

  # Search for latest where version  >= 0.34:
  my $repos = [ qw(http://cpan.pair.com http://my.company.com/DPAN) ];
  my $locator = Package::Locator->new( repository_urls => $repos );
  my $url = locator->locate( package => 'Test::More' version => 0.34, latest => 1);

  # Search for specific dist on multiple repositories...:
  my $repos = [ qw(http://cpan.pair.com http://my.company.com/DPAN) ];
  my $locator = Package::Locator->new( repository_urls => $repos );
  my $url = locator->locate( distribution => 'A/AU/AUTHOR/Foo-1.0.tar.gz');

=head1 DESCRIPTION

L<Package::Locator> attempts to answer the question: "Where can I find
a distribution that will provide this package?"  The answer is divined
by searching the indexes for one or more CPAN-like repositories.  If
you also provide a specific version number, L<Package::Locator> will
attempt to find a distribution with that version of the package, or
higher.  You can also ask to find the latest version of a package
across all the indexes.

L<Package::Locator> only looks at the index files for each repository,
and those indexes only contain information about the latest versions
of the packages within that repository.  So L<Package::Locator> is not
BackPAN magic -- you cannot use it to find precisely which
distribution a particular package (or file) came from.  For that
stuff, see C<"/See Also">.

=head1 CONSTRUCTOR

=head2 new( %attributes )

All the attributes listed below can be passed to the constructor, and
retrieved via accessor methods with the same name.  All attributes are
read-only, and cannot be changed once the object is constructed.

=head1 MOTIVATION

The L<CPAN> module also provides a mechanism for locating packages or
distributions, much like L<Package::Locator> does.  However, L<CPAN>
assumes that all repositories are CPAN mirrors, so it only searches
the first repository that it can contact.

My secret ambition is to fill the world with lots of DarkPAN
repositories -- each with its own set of distributions.  For that
scenario, I need to search multiple repositories at the same time.

=head1  SEE ALSO

If you need to locate a distribution that contains a precise version
of a file rather than just a version that is "new enough", then look
at some of these:

L<Dist::Surveyor>

L<BackPAN::Index>

L<BackPAN::Version::Discover>

