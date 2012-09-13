# ABSTRACT: Role for actions that commit changes to the repository

package Pinto::Role::Committable;

use Moose::Role;
use MooseX::Types::Moose qw(Bool Str);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has dryrun => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has message => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

#------------------------------------------------------------------------------
# TODO: When we support real revision history, make the message
# attribute required whenever the dryrun attribute is false.
# ------------------------------------------------------------------------------

1;

__END__
