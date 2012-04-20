# ABSTRACT: Interface for Action::Pull

package Pinto::Role::Interface::Action::Pull;

use Moose::Role;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action
         Pinto::Role::Attribute::target
         Pinto::Role::Attribute::stack
         Pinto::Role::Attribute::pin
         Pinto::Role::Attribute::norecurse );

#------------------------------------------------------------------------------

1;

__END__
