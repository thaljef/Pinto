# ABSTRACT: Role for actions that are transactional

package Pinto::Role::Action::Transactional;

use Moose::Role;

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
