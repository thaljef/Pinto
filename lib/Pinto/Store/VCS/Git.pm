package Pinto::Store::VCS::Git;

# ABSTRACT: Store your Pinto repository with Git

use Moose;

use Carp;

extends 'Pinto::Store::VCS';

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

override initialize => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git clone or git pull
};

#-------------------------------------------------------------------------------

override commit => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git commit and push
};

#-------------------------------------------------------------------------------

override tag => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git tag
};

#-------------------------------------------------------------------------------

override add => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git add
};

#-------------------------------------------------------------------------------

override remove => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git rm
};

#-------------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

This module is Not yet implemented.

=cut
