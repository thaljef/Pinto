# ABSTRACT: Interface for Action::Stack::Log

package Pinto::Role::Interface::Action::Stack::Log;

use Moose::Role;
use MooseX::Types::Moose qw(Bool Int);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action
         Pinto::Role::Attribute::stack
         Pinto::Role::Attribute::out );

#------------------------------------------------------------------------------

has revision => (
    is        => 'ro',
    isa       => Int,
    predicate => 'has_revision',
);

has detailed => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

1;

__END__
