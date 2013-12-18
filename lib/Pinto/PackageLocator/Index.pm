# ABSTRACT: The package index of a repository

package Pinto::PackageLocator::Index;

use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Path::Class;
use MooseX::MarkAsMethods (autoclean => 1);

use Carp;
use File::Temp;
use Path::Class;
use IO::Zlib;
use LWP::UserAgent;
use URI::Escape;
use URI;

#------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------

=attr repository_url => 'http://somewhere'

The base URL of the repository you want to get the index from.  This
is usually a CPAN mirror, but can be any site or directory that is
organized in a CPAN-like structure.  This attribute is required.

=cut

has repository_url => (
    is        => 'ro',
    isa       => Uri,
    required  => 1,
    coerce    => 1,
);

#------------------------------------------------------------------------

=attr user_agent => $user_agent_obj

The L<LWP::UserAgent> object that will fetch the index file.  If you
do not provide a user agent, then a default one will be constructed
for you.

=cut

has user_agent => (
   is          => 'ro',
   isa         => 'LWP::UserAgent',
   default     => sub { LWP::UserAgent->new() },
);

#------------------------------------------------------------------------

=attr cache_dir => '/some/directory/path'

The path (as a string or L<Path::Class::Dir> object) to a directory
where the index file will be cached.  If the directory does not exist,
it will be created for you.  If you do not specify a cache directory,
then a temporary directory will be used.  The temporary directory will
be deleted when your application terminates.

=cut

has cache_dir => (
   is         => 'ro',
   isa        => 'Path::Class::Dir',
   default    => sub { Path::Class::Dir->new( File::Temp::tempdir(CLEANUP => 1) ) },
   coerce     => 1,
);

#------------------------------------------------------------------------

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

#------------------------------------------------------------------------

=method index_file()

Returns the path to the local copy of the index file (as a
L<Path::Class::File>).

=cut

has index_file => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    init_arg   => undef,
    lazy_build => 1,
);

#------------------------------------------------------------------------

=method distributions

Returns a hashref representing the contents of the index.  The keys
are the paths to the distributions (as they appear in the index).  The
values are data structures that look like this:

  {
    path     => 'A/AU/AUTHOR/FooBar-1.0.tar.gz',
    source   => 'http://some.cpan.mirror'
    packages => [ ## See package structure below ## ]
  }

=cut

has distributions => (
   is         => 'ro',
   isa        => 'HashRef',
   init_arg   => undef,
   default    => sub { $_[0]->_data->{distributions} },
   lazy       => 1,
);


#------------------------------------------------------------------------


=method packages

Returns a hashref representing the contents of the index.  The keys
are the names of packages.  The values are data structures that look
like this:

  {
    name         => 'Foo',
    version      => '1.0',
    distribution => 'A/AU/AUTHOR/FooBar-1.0.tar.gz'
  }

=cut

has packages => (
   is         => 'ro',
   isa        => 'HashRef',
   init_arg   => undef,
   default    => sub { $_[0]->_data->{packages} },
   lazy       => 1,
);


#------------------------------------------------------------------------


has _data => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1,
);

#------------------------------------------------------------------------------

sub _build_index_file {
    my ($self) = @_;

    my $repos_url = $self->repository_url->canonical()->as_string();
    $repos_url =~ s{ /*$ }{}mx;         # Remove trailing slash
    $repos_url = URI->new($repos_url);  # Reconstitute as URI object

    my $cache_dir = $self->cache_dir->subdir( URI::Escape::uri_escape($repos_url) );
    $self->__mkpath($cache_dir);

    my $destination = $cache_dir->file('02packages.details.txt.gz');
    $destination->remove() if -e $destination and $self->force();

    my $source = URI->new( "$repos_url/modules/02packages.details.txt.gz" );

    my $response = $self->user_agent->mirror($source, $destination);
    $self->__handle_ua_response($response, $source, $destination);

    return $destination;
}

#------------------------------------------------------------------------------

sub _build__data {
    my ($self) = @_;

    my $file = $self->index_file->stringify;
    my $fh = IO::Zlib->new($file, 'rb') or croak "Failed to open index file $file: $!";
    my $index_data = $self->__read_index($fh);
    close $fh;

    return $index_data;
}

#------------------------------------------------------------------------------

sub __read_index {
    my ($self, $fh) = @_;

    my $inheader      = 1;
    my $packages      = {};
    my $distributions = {};
    my $source        = $self->repository_url();

    while (<$fh>) {

        if ($inheader) {
            $inheader = 0 if not m/ \S /x;
            next;
        }

        chomp;
        my ($package, $version, $dist_path) = split;
        my $dist_struct = $distributions->{$dist_path} ||= { source => $source, path => $dist_path };
        my $pkg_struct  = {name => $package, version => $version, distribution => $dist_path};
        push @{ $dist_struct->{packages} ||= [] }, $pkg_struct;
        $packages->{$package} = $pkg_struct;

    }

    return { packages      => $packages,
             distributions => $distributions };
}

#------------------------------------------------------------------------

sub __handle_ua_response {
    my ($self, $response, $source, $destination) = @_;

    return 1 if $response->is_success();   # Ok
    return 1 if $response->code() == 304;  # Not modified
    croak sprintf 'Request to %s failed: %s', $source, $response->status_line();
}

#------------------------------------------------------------------------------

sub __mkpath {
    my ($self, $dir) = @_;

    return 1 if -e $dir;
    $dir = dir($dir) unless eval { $dir->isa('Path::Class::Dir') };
    return $dir->mkpath() or croak "Failed to make directory $dir: $!";
}

#------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------
1;

__END__

=head1 SYNOPSIS

  use Package::Locator::Index;

  my $index = Package::Locator::Index->new( repository_url => 'http://somewhere' );
  my $dist  = $index->distributions->{'A/AU/AUTHOR/Foo-Bar-1.0.tar.gz'};
  my $pkg   = $index->packages->{'Foo::Bar'};

=head1 DESCRIPTION

B<This is a private module and there are no user-serviceable parts
here.  The API documentation is for my own reference only.>

L<Package::Locator::Index> is yet-another module for parsing the
contents of the F<02packages.details.txt> file from a CPAN-like
repository.

=head1 MOTIVATION

There are numerous existing modules for parsing the
F<02packages.details.txt> file, but I wasn't completely happy with any
of them.  Most of the existing modules transform the data into various
flavors of Distribution and Package objects. But I'm not ready to
commit to any particular API for Distributions and Packages (not even
one of my own).  So L<Package::Locator::Index> exposes the index data
as simple data structures.

=head1 CONSTRUCTOR

=head2 new( %attributes )

All the attributes listed below can be passed to the constructor, and
can be retrieved via accessor methods with the same name.  All
attributes are read-only, and cannot be changed once the object is
constructed.
