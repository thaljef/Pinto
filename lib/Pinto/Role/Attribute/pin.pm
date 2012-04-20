# ABSTRACT: Something that has a pin attribute

package Pinto::Role::Attribute::pin;

use Moose::Role;
use MooseX::Types::Moose qw(Bool);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has pin => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

1;

__END__
