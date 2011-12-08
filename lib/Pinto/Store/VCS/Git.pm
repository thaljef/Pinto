package Pinto::Store::VCS::Git;

# ABSTRACT: Store your Pinto repository with Git

use Moose;

use Carp;

extends 'Pinto::Store::VCS';

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

augment initialize => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git clone or git pull
};

#-------------------------------------------------------------------------------

augment commit => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git commit and push
};

#-------------------------------------------------------------------------------

augment tag => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git tag
};

#-------------------------------------------------------------------------------

augment add_path => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git add
};

#-------------------------------------------------------------------------------

augment remove_path => sub {
    croak __PACKAGE__ . 'is not implemented yet';
    # git rm
};

#-------------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

This module is Not yet implemented.

=cut
