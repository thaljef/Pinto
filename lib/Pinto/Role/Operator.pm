# ABSTRACT: Something that operates on the repository

package Pinto::Role::Operator;

use Moose::Role;
use MooseX::Types::Moose qw(Bool);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

requires qw(operative_stack);

#-----------------------------------------------------------------------------

has dryrun => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#-----------------------------------------------------------------------------

1;

__END__
