# ABSTRACT: Interface for Action::Stack::Remove

package Pinto::Role::Interface::Action::Stack::Remove;

use Moose::Role;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action
         Pinto::Role::Attribute::stack );

#------------------------------------------------------------------------------
1;

__END__
