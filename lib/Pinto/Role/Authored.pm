package Pinto::Role::Authored;

# ABSTRACT: Something that has an author

use Moose::Role;

use Carp;
use English qw(-no_match_vars);
use Pinto::Types qw(AuthorID);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has author => (
    is         => 'ro',
    isa        => AuthorID,
    coerce     => 1,
    lazy_build => 1,
);

#------------------------------------------------------------------------------

sub _build_author {

    # Look at typical environment variables
    for my $var ( qw(USERNAME USER LOGNAME) ) {
        return uc $ENV{$var} if $ENV{$var};
    }

    # Try using pwent.  Probably only works on *nix
    if (my $name = getpwuid($REAL_USER_ID)) {
        return uc $name;
    }

    # Otherwise, we are hosed!
    croak 'Unable to determine your user name';

}

#------------------------------------------------------------------------------
1;

__END__

