package Pinto::IndexWriter;

# ABSTRACT: Write records to an 02packages file

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
# Attributes

has db => (
    is       => 'ro',
    isa      => 'Pinto::Database',
    required => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw(Pinto::Role::Loggable);

#------------------------------------------------------------------------------
# Methods

sub write {                                       ## no critic (BuiltinHomonym)
    my ($self, %args) = @_;

    my $file = $args{file};
    $self->info("Writing index at $file");

    open my $fh, '>:gzip', $file;
    $self->_write_header($fh, $file);
    $self->_write_packages($fh);
    close $fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _write_header {
    my ($self, $fh, $filename) = @_;

    my $base    = $filename->basename();
    my $url     = 'file://' . $filename->absolute->as_foreign('Unix');
    my $version = $Pinto::IndexWriter::VERSION || 'UNKNOWN VERSION';
    my $count   = $self->db->get_all_indexed_packages->count();

    print {$fh} <<"END_PACKAGE_HEADER";
File:         $base
URL:          $url
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Pinto::IndexWriter $version
Line-Count:   $count
Last-Updated: @{[ scalar localtime() ]}

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _write_packages {
    my ($self, $fh) = @_;

    my $rs = $self->db->get_all_indexed_packages();

    while ( my $pkg = $rs->next() ) {
        print {$fh} $pkg->to_index_string();
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
            my @package_names = map {$_->name()} $dist->packages();
            $self->packages->delete($_) for @package_names;
            push @removed_dists, $dist;
        }

    }
    return @removed_dists;
}

#------------------------------------------------------------------------------

sub remove_dist {
    my ($self, $dist) = @_;

    $dist = $dist->location()
        if eval { $dist->isa('Pinto::Distribution') };

    my $deleted = $self->distributions->delete( $dist );
    return $self if not $deleted;

    $self->packages->delete($_) for $deleted->packages();

    return $deleted;
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




