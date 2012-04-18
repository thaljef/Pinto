# ABSTRACT: Interface for Action::Stack::Create

package Pinto::Role::Interface::Action::Stack::Create;

use Moose::Role;
use MooseX::Types::Moose qw(Str);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action
         Pinto::Role::Attribute::stack );

#------------------------------------------------------------------------------

has description => (
    is      => 'ro',
    isa     => Str,
    default => 'no description was given',
);

#------------------------------------------------------------------------------

1;

__END__
