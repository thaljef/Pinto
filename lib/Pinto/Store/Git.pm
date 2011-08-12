package Pinto::Store::Git;

# ABSTRACT: Store your Pinto repository with Git

use Moose;

use Carp;

extends 'Pinto::Store';

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

override is_initialized => sub {
    croak __PACKAGE__ . ' is not implemented yet';
    # -e .git
};

#-------------------------------------------------------------------------------

override initialize => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git clone or git pull
};

#-------------------------------------------------------------------------------

override finalize => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git commit and push
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
