# ABSTRACT: Storage for distribution archives

package Pinto::Store;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use CPAN::Checksums;

use Pinto::Util qw(debug throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::UserAgent );

#------------------------------------------------------------------------------

has repo => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    weak_ref => 1,
    required => 1,
);

#------------------------------------------------------------------------------
# TODO: Use named arguments here...

sub add_archive {
    my ( $self, $origin, $destination ) = @_;

    throw "$origin does not exist" if not -e $origin;
    throw "$origin is not a file"  if not -f $origin;

    $self->fetch( from => $origin, to => $destination );
    $self->update_checksums( directory => $destination->parent );

    return $self;

}

#------------------------------------------------------------------------------
# TODO: Use named arguments here...

sub remove_archive {
    my ( $self, $archive_file ) = @_;

    $self->remove_path( path => $archive_file );

    $self->update_checksums( directory => $archive_file->parent );

    return $self;
}

#------------------------------------------------------------------------------

sub remove_path {
    my ( $self, %args ) = @_;

    my $path = $args{path};
    throw "Must specify a path" if not $path;

    return if not -e $path;

    $path->remove or throw "Failed to remove path $path: $!";

    while ( my $dir = $path->parent ) {
        last if $dir->children;
        debug("Removing empty directory $dir");
        $dir->remove or throw "Failed to remove directory $dir: $!";
        $path = $dir;
    }

    return $self;
}

#------------------------------------------------------------------------------

sub update_checksums {
    my ( $self, %args ) = @_;
    my $dir = $args{directory};

    return 0 if $ENV{PINTO_NO_CHECKSUMS};
    return 0 if not -e $dir;                # Would be fishy!

    my @children = $dir->children;
    return if not @children;

    my $cs_file = $dir->file('CHECKSUMS');

    if ( -e $cs_file && @children == 1 ) {
        $self->remove_path( path => $cs_file );
        return 0;
    }

    debug("Generating $cs_file");

    try { CPAN::Checksums::updatedir($dir) } catch { throw "CHECKSUM generation failed for $dir: $_" };

    return $self;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

L<Pinto::Store> is the base class for Pinto Stores.  It provides the
basic API for adding/removing distribution archives to the store.
Subclasses implement the underlying logic by augmenting the methods
declared here.

=cut
