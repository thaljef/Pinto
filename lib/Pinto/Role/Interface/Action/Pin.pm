# ABSTRACT: Interface for Action::Pin

package Pinto::Role::Interface::Action::Pin;

use Moose::Role;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action
         Pinto::Role::Attribute::target
         Pinto::Role::Attribute::stack );

#------------------------------------------------------------------------------

1;

__END__
