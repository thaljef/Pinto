# ABSTRACT: Interface for Action::Add

package Pinto::Role::Interface::Action::Add;

use Moose::Role;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action
         Pinto::Role::Attribute::author
         Pinto::Role::Attribute::archive
         Pinto::Role::Attribute::stack
         Pinto::Role::Attribute::pin
         Pinto::Role::Attribute::norecurse );

#------------------------------------------------------------------------------

1;

__END__
