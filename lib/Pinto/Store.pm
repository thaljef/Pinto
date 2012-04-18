package Pinto::Store;

# ABSTRACT: Base class for storage of a Pinto repository

use Moose;

use Carp;
use Try::Tiny;
use CPAN::Checksums;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------
# Methods

=method initialize()

This method is called before each batch of Pinto events, and is
responsible for doing any setup work that is required by the Store.
This could include making a directory on the file system, checking out
or updating a working copy, cloning, or pulling commits.  If the
initialization fails, an exception should be thrown.  The default
implementation simply creates the repository directory, if it isn't
already there.  Returns a reference to this Store.

=cut

sub initialize {
    my ($self) = @_;

    inner();

    return $self;
}

#------------------------------------------------------------------------------

=method commit(message => 'what happened')

This method is called after each batch of Pinto events and is
responsible for doing any work that is required to commit the Store.
This could include scheduling files for addition/deletion, pushing
commits to a remote repository.  If the commit fails, an exception
should be thrown.  The default implementation does nothing.  Returns a
reference to this Store.

=cut

sub commit {
    my ($self) = @_;

    $self->add_path( path => $self->config->pinto_dir() );
    $self->add_path( path => $self->config->modules_dir() );
    $self->add_path( path => $self->config->mailrc_file() );
    inner();

    return $self;
}

#------------------------------------------------------------------------------

=method tag( tag => $tag_name )

Tags the store.  For some subclasses, this means performing some kind
of "tag" operations.  For others, it could mean doing a copy
operation.  The default implementation does nothing.

=cut

sub tag {
    my ($self) = @_;

    inner();

    return $self;
}

#------------------------------------------------------------------------------
# TODO: Use named arguments here...

sub add_archive {
    my ($self, $archive_file) = @_;

    confess "$archive_file is not a file"
        if not -f $archive_file;

    $self->add_path( path => $archive_file );
    $self->update_checksums( directory => $archive_file->parent() );

    return $self;

}

#------------------------------------------------------------------------------
# TODO: Use named arguments here...

sub remove_archive {
    my ($self, $archive_file) = @_;

    $self->remove_path( path => $archive_file );

    $self->update_checksums( directory => $archive_file->parent() );

    return $self;
}

#------------------------------------------------------------------------------

sub add_path {
    my ($self, %args) = @_;

    my $path = $args{path};
    confess "Must specify a path" if not $path;
    confess "Path $path does not exist" if not -e $path;

    inner();

    return $self;
}

#------------------------------------------------------------------------------

sub remove_path {
    my ($self, %args) = @_;

    my $path = $args{path};
    confess "Must specify a path" if not $path;

    return if not -e $path;

    inner();

    return $self;
}

#------------------------------------------------------------------------------

sub update_checksums {
    my ($self, %args) = @_;
    my $dir = $args{directory};

    #return 0 if not -e $dir;  # Smells fishy

    my @children = grep { ! Pinto::Util::is_vcs_file($_) } $dir->children();
    return 0 if not @children;

    my $cs_file = $dir->file('CHECKSUMS');

    if ( -e $cs_file && @children == 1 ) {
        $self->remove_path(path => $cs_file);
        return 0;
    }

    $self->debug("Generating $cs_file");

    try   { CPAN::Checksums::updatedir($dir) }
    catch { confess "CHECKSUM generation failed for $dir: $_" };

    $self->add_path(path => $cs_file);

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
