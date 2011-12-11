package Pinto::Store::VCS::Git::Remote;

# ABSTRACT: Store your Pinto repository remotely with Git

use Moose;

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

1;

__END__

=head1 DESCRIPTION

This module is Not yet implemented.

=cut
