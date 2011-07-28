package Pinto::Index;

# ABSTRACT: Represents an 02packages.details.txt file

use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class;

use Carp;
use Compress::Zlib;
use Path::Class qw();

use Pinto::Package;

use overload ('+' => '__plus', '-' => '__minus');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

=attr packages_by_name()

Returns a reference to a hash.  The keys will be the names of every
package in this Index (as strings) and the values will be the
corresponding L<Pinto::Package> object.

=cut

has 'packages_by_name' => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
    init_arg   => undef,
    writer     => '_set_packages_by_name',
);

=attr packages_by_file()

Returns a reference to hash.  The keys will be the path to every
archive file in this Index (as strings) and the values will be a
reference to an array of all the L<Pinto::Package> objects that belong
in that archive file.  Note that the keys are the paths as they appear
in the index.  This means they will be Unix-style paths and will be
relative to the F<authors/id> directory.

=cut

has 'packages_by_file' => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
    init_arg   => undef,
    writer     => '_set_packages_by_file',
);

=attr file()

Returns the path to the file this Index was created from (as a
Path::Class::File).  If you constructed this index by hand (rather
than reading from a file) this attribute may be undefined.

=cut

has 'file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
);

#------------------------------------------------------------------------------

=for Pod::Coverage BUILD

Internal, not documented

=cut


sub BUILD {
    my ($self) = @_;
    if (my $file = $self->file()){
        $self->read(file => $file);
    }
    return $self;
}

#------------------------------------------------------------------------------

=method read(file => '02packages.details.txt.gz')

Populates this Index by reading the packages from a file.  This file
is expected to conform to the F<02packages.details.txt> format, and
should be C<gzipped>.  You normally should not need to call this
method, as it will be called for you if you supply a C<file> argument
to the constructor.

=cut

sub read  {
    my ($self, %args) = @_;

    my $file = $args{file} || $self->file()
        or croak "This index has no file attribute, so you must specify one";

    $file = Path::Class::file($file) unless eval { $file->isa('Path::Class::File') };

    return if not -e $file;

    my $fh = $file->openr();
    my $gz = Compress::Zlib::gzopen($fh, "rb")
        or die "Cannot open $file: $Compress::Zlib::gzerrno";

    my $inheader = 1;
    while ($gz->gzreadline($_) > 0) {
        if ($inheader) {
            $inheader = 0 if not /\S/;
            next;
        }
        chomp;
        my ($n, $v, $f) = split;
        my $package = Pinto::Package->new(name => $n, version => $v, file => $f);
        $self->add($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

=attr write(file => '02packages.details.txt.gz')

Writes this Index to file in the format of the
F<02packages.details.txt> file.  The file will also be C<gzipped>.  If
the C<file> argument is not explicitly given here, the name of the
file is taken from the C<file> attribute for this Index.

=cut

sub write {
    my ($self, %args) = @_;

    # TODO: Accept a file handle argument

    my $file = $args{file} || $self->file()
        or croak 'This index has no file attribute, so you must specify one';

    $file = Path::Class::file($file) unless eval { $file->isa('Path::Class::File') };

    $file->dir()->mkpath(); # TODO: log & error check
    my $gz = Compress::Zlib::gzopen( $file->openw(), 'wb' );
    $self->_gz_write_header($gz);
    $self->_gz_write_packages($gz);
    $gz->gzclose();

    return $self;
}

#------------------------------------------------------------------------------

sub _gz_write_header {
    my ($self, $gz) = @_;

    my ($file, $url) = $self->file()
        ? ($self->file()->basename(), 'file://' . $self->file()->as_foreign('Unix') )
        : ('UNKNOWN', 'UNKNOWN');

    $gz->gzwrite( <<END_PACKAGE_HEADER );
File:         $file
URL:          $url
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Pinto::Index 0.01
Line-Count:   @{[ $self->package_count() ]}
Last-Updated: @{[ scalar localtime() ]}

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _gz_write_packages {
    my ($self, $gz) = @_;

    for my $package ( @{ $self->packages() } ) {
        $gz->gzwrite($package->to_string() . "\n");
    }

    return $self;
}

#------------------------------------------------------------------------------

=attr merge( @packages )

Adds a list of L<Pinto::Package> objects to this Index, and removes
any existing packages that conflict with the added ones.  Use this
method when combining an Index of private packages with an Index of
public packages.

=cut

sub merge {
    my ($self, @packages) = @_;

    # Maybe instead...
    # $self->remove($_) for @packages;
    # $self->add($_)    for @packages;

    for my $package (@packages) {
        $self->remove($package);
        $self->add($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

=attr add( @packages)

Unconditionally adds a list of L<Pinto::Package> objects to this
Index.  If the index already contains packages by the same name, they
will be overwritten.  Use this method only when you know that the
names of all the added packages are unique.

=cut

sub add {
    my ($self, @packages) = @_;

    for my $package (@packages) {
        $self->packages_by_name()->put($package->name(), $package);
        ($self->packages_by_file()->{$package->file()} ||= [])->push($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

=method reload()

Clears all the packages in this Index and reloads them from the file
specified by the C<file> attribute.

=cut

sub reload {
    my ($self) = @_;

    return $self->clear()->read();
}

#------------------------------------------------------------------------------

=method clear()

Removes all packages from this Index.

=cut

sub clear {
    my ($self) = @_;

    $self->_set_packages_by_name( {} );
    $self->_set_packages_by_file( {} );

    return $self;
}

#------------------------------------------------------------------------------

=method remove( @packages )

Removes the packages from the index.  Whenever a package is removed, all
the other packages that belonged in the same archive are also removed.
Arguments can be L<Pinto::Package> objects or package names as strings.

=cut

sub remove {
    my ($self, @package_names) = @_;

    my @removed = ();
    for my $name (@package_names) {

      if (my $incumbent = $self->packages_by_name()->at($name)) {
          # Remove the file that contains the incumbent package and
          # then remove all packages that were contained in that file
          my $kin = $self->packages_by_file()->delete($incumbent->file());
          $self->packages_by_name()->delete($_) for map {$_->name()} @{$kin};
          push @removed, $kin->flatten();
      }

    }
    return @removed;
}

#------------------------------------------------------------------------------

=method package_count()

Returns the total number of packages currently in this Index.

=cut

sub package_count {
    my ($self) = @_;
    return $self->packages_by_name()->keys()->length();
}

#------------------------------------------------------------------------------

=method packages()

Returns a reference to an array of all the L<Pinto::Package> objects
in this index, sorted by name.

=cut

sub packages {
    my ($self) = @_;
    my $sorter = sub { $_[0]->name() cmp $_[1]->name() };
    return $self->packages_by_name()->values()->sort($sorter);
}

#------------------------------------------------------------------------------

=method files()

Returns a reference to a sorted array of paths to all the files in
this index (as Path::Class::File objects). Note that paths will be as
they appear in the index, which means they will be in Unix format and
relative to the F<authors/id> directory.

=cut

sub files {
    my ($self) = @_;
    return $self->packages_by_file()->keys()->sort();
}

#------------------------------------------------------------------------------

=method files_native(@base)

Same as the C<files()> method, except the paths are converted to your
OS.  The C<@base> can be a series of L<Path::Class::Dir> objects or
path fragments (as strings).  If given, all the returned paths will
have C<@base> prepended to them.

=cut

sub files_native {
    my ($self, @base) = @_;
    my $mapper = sub { return Pinto::Util::native_file(@base, $_[0]) };
    return $self->files()->map($mapper);
}

#------------------------------------------------------------------------------

=method validate()

Checks to see if the internal state of this Index is sane.  Basically,
every package must map to a file, and vice-versa.  If not, an
exception is thrown.

=cut

sub validate {
    my ($self) = @_;

    for my $package ( $self->packages_by_file()->values()->map( sub {@{$_[0]}} )->flatten() ) {
        my $name = $package->name();
        $self->packages_by_name->exists($name)
            or croak "Validation of package $name failed";
    }

    for my $package ( $self->packages_by_name()->values()->flatten() ) {
        my $file = $package->file();
        $self->packages_by_file->exists($file)
            or croak "Validation of file $file failed";
    }

    return $self;
}

#------------------------------------------------------------------------------

sub __plus {
    my ($self, $other, $swap) = @_;
    ($self, $other) = ($other, $self) if $swap;
    my $class = ref $self;
    my $result = $class->new();
    $result->add( @{$self->packages()} );
    $result->merge( @{$other->packages()} );
    return $result;
}

#------------------------------------------------------------------------------

sub __minus {
    my ($self, $other, $swap) = @_;
    ($self, $other) = ($other, $self) if $swap;
    my $class = ref $self;
    my $result = $class->new();
    $result->add( @{$self->packages()} );
    $result->remove( @{$other->packages()} );
    return $result;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut




