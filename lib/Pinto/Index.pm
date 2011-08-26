package Pinto::Index;

# ABSTRACT: Represents an 02packages.details.txt file

use autodie;

use Moose;
use Moose::Autobox;

use MooseX::Types::Moose qw(HashRef Bool);
use Pinto::Types 0.017 qw(File);

use Carp;
use PerlIO::gzip;
use Path::Class qw();

use Pinto::Package;
use Pinto::Distribution;

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
    isa        => HashRef,
    init_arg   => undef,
    lazy_build => 1,
);

has distributions => (
    is          => 'ro',
    isa         => HashRef,
    init_arg    => undef,
    lazy_build  => 1,
);

has file  => (
    is        => 'ro',
    isa       => File,
    predicate => 'has_file',
    coerce    => 1,
);

has noclobber => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Loggable);

#------------------------------------------------------------------------------
# Moose builders

sub _build_packages { return {} }

sub _build_distributions { return {} }

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    $self->load() if $self->has_file()
      and -e $self->file();

    return $self;
}

#------------------------------------------------------------------------------
# Methods

sub load {
    my ($self) = @_;

    my $file = $self->file();
    $self->logger->debug("Reading index at $file");

    # TODO: maybe support reading from non-zipped files?

    open my $fh, '<:gzip', $file;
    $self->_load($fh);
    close $fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _load {
    my ($self, $fh) = @_;

    my $inheader = 1;
    while (<$fh>) {

        if ($inheader) {
            $inheader = 0 if not m/ \S /x;
            next;
        }

        chomp;
        my ($name, $version, $location) = split;

        my $dist = $self->distributions->{$location}
          ||= Pinto::Distribution->new(location => $location);

        my $pkg = Pinto::Package->new( name => $name,
                                       dist => $dist,
                                       version => $version );

        $self->packages->put($name, $pkg);
        $dist->add_packages($pkg);
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

sub write {                                       ## no critic (BuiltinHomonym)
    my ($self, %args) = @_;

    # TODO: Accept a file handle argument

    my $file = $args{file} || $self->file()
        or croak 'This index has no file attribute, so you must specify one';

    $file = Path::Class::file($file) unless eval { $file->isa('Path::Class::File') };
    $self->logger->debug("Writing index at $file");

    open my $fh, '>:gzip', $file;
    $self->_write_header($fh);
    $self->_write_packages($fh);
    close $fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _write_header {
    my ($self, $fh) = @_;

    my ($file, $url) = $self->file()
        ? ($self->file->basename(), 'file://' . $self->file->as_foreign('Unix') )
        : ('UNKNOWN', 'UNKNOWN');

    my $version = $Pinto::Index::VERSION || 'UNKNOWN VERSION';

    print {$fh} <<"END_PACKAGE_HEADER";
File:         $file
URL:          $url
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Pinto::Index $version
Line-Count:   @{[ $self->package_count() ]}
Last-Updated: @{[ scalar localtime() ]}

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _write_packages {
    my ($self, $fh) = @_;

    my $sorter = sub { $_[0]->{name} cmp $_[1]->{name} };
    my $packages = $self->packages->values->sort($sorter);

    for my $package ( $packages->flatten() ) {
        print {$fh} $package->to_index_string();
    }

    return $self;
}

#------------------------------------------------------------------------------

sub add {
    my ($self, @packages) = @_;

    my @removed_dists;
    @removed_dists = $self->remove( @packages ) unless $self->noclobber();

    for my $package (@packages) {

        my $name = $package->name();
        $self->packages->put( $name, $package );

        my $location = $package->dist->location();
        $self->distributions->put( $location, $package->dist() );
    }

    return @removed_dists;
}

#------------------------------------------------------------------------------

=method reload()

Clears all the packages in this Index and reloads them from the file
specified by the C<file> attribute.

=cut

sub reload {
    my ($self) = @_;

    $self->clear();
    $self->load();

    return $self;
}

#------------------------------------------------------------------------------

=method clear()

Removes all packages from this Index.

=cut

sub clear {
    my ($self) = @_;

    $self->clear_packages();
    $self->clear_distributions();

    return $self;
}

#------------------------------------------------------------------------------

=method remove( @packages )

Removes the packages from the index.  Whenever a package is removed, all
the other packages that belonged in the same distribution are also removed.
Arguments can be L<Pinto::Package> objects or package names as strings.

=cut

sub remove {
    my ($self, @packages) = @_;

    my @removed_dists = ();
    for my $package (@packages) {

        $package = $package->name()
            if eval { $package->isa('Pinto::Package') };

        if (my $incumbent = $self->packages->at($package)) {
            my $location = $incumbent->dist->location();
            my $dist = $self->distributions->delete( $location );
            my @package_names = map {$_->name()} $dist->packages()->flatten();
            $self->packages->delete($_) for @package_names;
            push @removed_dists, $dist;
        }

    }
    return @removed_dists;
}

#------------------------------------------------------------------------------

=method package_count()

Returns the total number of packages currently in this Index.

=cut

sub package_count {
    my ($self) = @_;

    return $self->packages->keys->length();
}

#------------------------------------------------------------------------------

sub find {
    my ($self, %args) = @_;

    if (my $pkg = $args{package}) {
        return $self->packages->at($pkg);
    }
    elsif (my $file = $args{file}) {
        my $dist = $self->distributions->at($file);
        return $dist ? $dist->packages->flatten() : ();
    }
    elsif (my $author = $args{author}) {
        my $filter = sub { $_[0]->file() eq $author };
        return $self->packages->values->grep( $filter )->flatten();
    }

    croak "Don't know how to find by %args";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

The role of L<Pinto::IndexManager> and L<Pinto::Index> is to create an
abstraction layer between the rest of the application and the details
of managing the 02packages index file.  At the moment, we use three
separate index files: one for locally added packages, one for mirrored
packages, and a master index that combines the other two according to
specific rules.  But this file-based design is ugly and doesn't
perform well.  So in the future, I hope to replace those files with a
proper database.

=cut




