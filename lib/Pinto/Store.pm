package Pinto::Store;

# ABSTRACT: Back-end storage for a Pinto repoistory

use Moose;
use Path::Class;

#---------------------------------------------------------------------------------------

# VERSION

#---------------------------------------------------------------------------------------

=attr config()

Returns the L<Pinto::Config> object for this Store.  This must be
provided through the constructor and should be the same
L<Pinto::Config> that L<Pinto> has.

=cut

has config => (
    is       => 'ro',
    isa      => 'Pinto::Config',
    required => 1,
);

#---------------------------------------------------------------------------------------

=method initialize()

This method is called before each Pinto action, and is responsible for
doing any setup work that is required by the Store.  This could
include making a directory on the file system, checking out some
directory from an SCM repository, or cloning an SCM repository.  If
the initialization fails, an exception should be thrown.

=cut

sub initialize {
    my ($self, %args) = @_;

    my $local = $args{local} || $self->config()->get_required('local');
    Path::Class::dir($local)->mkpath();

    return 1;
}

#---------------------------------------------------------------------------------------

=method finalize(message => 'what happened')

This method is called after each Pinto action and is responsible for
doing any work that is required to commit the Store.  This could
include committing changes, pushing commits to a remote repository,
and/or making a tag.  If the finalization fails, an exception should
be thrown.

=cut

sub finalize {
    my ($self, %args) = @_;

    return 1;
}


#---------------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

L<Pinto::Store> util is the default back-end for a Pinto repository.
It basically just represents files on disk.  You should look at
L<Pinto::Store::Svn> or L<Pinto::Store::Git> for a more interesting
example.

=cut
