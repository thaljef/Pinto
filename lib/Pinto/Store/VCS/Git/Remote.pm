package Pinto::Store::VCS::Git::Remote;

# ABSTRACT: Store your Pinto repository remotely with Git

use Moose;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# ISA

extends 'Pinto::Store::VCS::Git';

#-------------------------------------------------------------------------------

augment initialize => sub {
    my ($self) = @_;

    $self->_git->run( qw(pull) );

    return $self;
};

#-------------------------------------------------------------------------------

augment commit => sub {
    my ($self, %args) = @_;

    $self->_git->run( push => qw(--quiet) );

    return $self;
};

#-------------------------------------------------------------------------------

augment tag => sub {
    my ($self, %args) = @_;

    $self->_git->run( push => qw(--quiet --tags) );

    return $self;
};

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  # Assume you want to push to a central repository on some server, so you've
  # constructed a bare repository at git://some_server/PINTO.git

  # If you don't already have a Pinto repository, create one (notice the --store option here)
  $> pinto-admin --repos=~/PINTO create --store=Pinto::Store::VCS::Git::Remote

  # If you do already have a repository, edit its config (at $REPOS/.pinto/config/pinto.ini)
  store = Pinto::Store::VCS::Git::Remote

  # Initialize Pinto repository into Git
  $> cd ~/PINTO
  $> git init

  # Add initial files and commit
  $> git add .pinto authors modules
  $> git commit -a -m 'New Pinto repos'

  # Establish tracking and push to remote repository
  $> git push -u git://some_server/PINTO.git master

=head1 DESCRIPTION

L<Pinto::Store::VCS::Git::Remote> is a back-end for L<Pinto> that
stores the repository inside a remote Git repository.  This Store is
basically the same as L<Pinto::Store::VCS::Git>, with the difference
that it performs a C<pull> during initialization, and does a C<push>
after each commit and tag operation.  Before you can effectively use
this Store, you must initialize or clone a Git repository that
contains your Pinto repository.  Also, you must establish a remote
repository that you can pull/push to (see L</SYNOPSIS> for the
typical procedure).

If you don't need to pull/push to a remote repository, then use
L<Pinto::Store::VCS::Git> instead.

=head1 CAVEATS

=over 4

=item The C<git> program is required.

You must have the binary C<git> tool installed somwhere in uour
C<$PATH> for this Store to work.

=item No built-in support for authentication.

All authentication is handled by the C<git> client.  So you must have
the credentials for your repository already configured with C<git>.
If you cannot or will not allow C<git> to cache your credentials, then
this module will not work.

=back

=cut
