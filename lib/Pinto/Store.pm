package Pinto::Store;

# ABSTRACT: Back-end storage for a Pinto repoistory

use Moose;
use Path::Class;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Configurable Pinto::Role::Loggable);

#------------------------------------------------------------------------------
# Methods

=method initialize()

This method is called before each batch of Pinto events, and is
responsible for doing any setup work that is required by the Store.
This could include making a directory on the file system, checking out
or updating a working copy, cloning, or pulling commits.  If the
initialization fails, an exception should be thrown.

The default implementation simply creates a directory.

=cut

sub initialize {
    my ($self) = @_;

    my $local = $self->config()->local();
    $local = dir($local) if not eval {$local->isa('Path::Class::Dir') };

    if (not -e $local) {
        $self->logger()->log("Making directory at $local ... ", {nolf => 1});
        $local->mkpath(); # TODO: Set dirmode and verbosity here.
        $self->logger()->log("DONE");
    }

    return 1;
}

#------------------------------------------------------------------------------

=method is_initialized()

Returns true if the store appears to be initialized.  In this base class,
it simply means that the working directory exists.  For other subclasses,
this could mean that the working copy is up-to-date.

=cut

sub is_initialized {
    my ($self) = @_;
    return -e $self->config()->local();
}

#------------------------------------------------------------------------------

=method finalize(message => 'what happened')

This method is called after each batch of Pinto events and is
responsible for doing any work that is required to commit the Store.
This could include scheduling files for addition/deletion, pushing
commits to a remote repository, and/or making a tag.  If the
finalization fails, an exception should be thrown.

=cut

sub finalize {
    my ($self, %args) = @_;
    # TODO: Default implementation - delete empty directories.
    return 1;
}


#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

L<Pinto::Store> util is the default back-end for a Pinto repository.
It basically just represents files on disk.  You should look at
L<Pinto::Store::Svn> or L<Pinto::Store::Git> for a more interesting
example.

=cut
