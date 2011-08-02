package Pinto::Index;

# ABSTRACT: Represents an 02packages.details.txt file

use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class;

use Carp;
use Compress::Zlib;
use List::MoreUtils qw(uniq);
use Path::Class qw();

use Pinto::Package;

use overload ('+' => '__plus', '-' => '__minus');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

=attr packages()

Returns a reference to hash of packages listed in this index.  The
keys are packages names (as strings) and the values are the associated
L<Pinto::Package> objects.

=cut

has packages => (
    is         => 'ro',
    isa        => 'HashRef',
    writer     => '_set_packages',
    lazy_build => 1,
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
# Builders

sub _build_packages {
    my ($self) = @_;

    my $file = $self->file() or return {};
    -e $file or return {};  # TODO: hmmm....

    my $fh = $file->openr();
    my $gz = Compress::Zlib::gzopen($fh, "rb")
        or die "Cannot open $file: $Compress::Zlib::gzerrno";

    my $inheader = 1;
    my $packages = {};
    while ($gz->gzreadline($_) > 0) {
        if ($inheader) {
            $inheader = 0 if not /\S/;
            next;
        }

        chomp;
        my ($name, $version, $file) = split;
        $packages->{$name} = Pinto::Package->new( name    => $name,
                                                  file    => $file,
                                                  version => $version );

    }

    return $packages;
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

    print ">> Writing index at $file\n";

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

    my $sorter = sub { $_[0]->name() cmp $_[1]->name() };
    my $packages = $self->packages()->values()->sort($sorter);
    for my $package ( $packages->flatten() ) {
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

    $self->remove($_) for @packages;
    $self->add($_)    for @packages;

    return $self;
}

#------------------------------------------------------------------------------

=attr add( @packages)

Unconditionally adds a list of L<Pinto::Package> objects to this
Index.  If the index already contains packages by the same name, they
will be overwritten.

=cut

sub add {
    my ($self, @packages) = @_;

    for my $package (@packages) {
        $self->packages()->put($package->name(), $package);
    }

    return $self;
}

#------------------------------------------------------------------------------

=method reload()

Clears all the packages in this Index and reloads them from the file
specified by the C<file> attribute.

=cut

sub reload {
    my ($self, %args) = @_;

    return $self->clear()->read(%args);
}

#------------------------------------------------------------------------------

=method clear()

Removes all packages from this Index.

=cut

sub clear {
    my ($self) = @_;

    $self->_set_packages( {} );

    return $self;
}

#------------------------------------------------------------------------------

=method remove( @packages )

Removes the packages from the index.  Whenever a package is removed, all
the other packages that belonged in the same archive are also removed.
Arguments can be L<Pinto::Package> objects or package names as strings.

=cut

sub remove {
    my ($self, @packages) = @_;

    my @removed = ();
    for my $package (@packages) {

        $package = $package->name()
            if eval { $package->isa('Pinto::Package') };

        if (my $incumbent = $self->packages()->at($package)) {
            # Remove the file that contains the incumbent package and
            # then remove all packages that were contained in that file
            my $filter = sub { $_[0]->file() eq $incumbent->file() };
            my @kin = $self->packages()->values()->grep($filter)->flatten();
            $self->packages()->delete($_) for map {$_->name()} @kin;
            push @removed, @kin;
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

    return $self->packages()->keys()->length();
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

    my $mapper = sub { $_[0]->file() };

    return uniq $self->packages()->values()->map($mapper)->sort()->flatten();
}

#------------------------------------------------------------------------------

sub find {
    my ($self, %args) = @_;

    if (my $pkg = $args{package}) {
        return $self->packages()->at($pkg);
    }
    elsif (my $file = $args{file}) {
        my $filter = sub { $_[0]->file() eq $file };
        return $self->packages()->values()->grep( $filter )->flatten();
    }
    elsif (my $author = $args{author}) {
        my $filter = sub { $_[0]->file() eq $author };
        return $self->packages()->values()->grep( $filter )->flatten();
    }

    croak "Don't know how to find by %args";
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

sub __plus {
    my ($self, $other, $swap) = @_;

    ($self, $other) = ($other, $self) if $swap;
    my $class = ref $self;
    my $result = $class->new();
    $result->add( $self->packages()->values()->flatten() );
    $result->merge( $other->packages()->values()->flatten() );

    return $result;
}

#------------------------------------------------------------------------------

sub __minus {
    my ($self, $other, $swap) = @_;

    ($self, $other) = ($other, $self) if $swap;
    my $class = ref $self;
    my $result = $class->new();
    $result->add( $self->packages()->values()->flatten() );
    $result->remove( $other->packages()->values()->flatten() );

    return $result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta()->make_immutable();

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut




