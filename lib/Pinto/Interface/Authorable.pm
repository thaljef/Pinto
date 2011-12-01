package Pinto::Interface::Authorable;

# ABSTRACT: Something that has an author

use Moose::Role;

use Pinto::Types qw(AuthorID);
use Pinto::Exceptions qw(throw_fatal);

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

sub _build_author {                                  ## no critic (FinalReturn)

    # Look at typical environment variables
    for my $var ( qw(USERNAME USER LOGNAME) ) {
        return uc $ENV{$var} if $ENV{$var};
    }

    # Try using pwent.  Probably only works on *nix
    if (my $name = getpwuid($<)) {
        return uc $name;
    }

    # Otherwise, we are hosed!
    throw_fatal 'Unable to determine your user name';

}

#------------------------------------------------------------------------------
1;

__END__

