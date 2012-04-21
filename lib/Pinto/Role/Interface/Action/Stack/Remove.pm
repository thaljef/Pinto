# ABSTRACT: Interface for Action::Stack::Remove

package Pinto::Role::Interface::Action::Stack::Remove;

use Moose::Role;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action );

#------------------------------------------------------------------------------

has stack => (
   is       => 'ro',
   isa      => StackName,
   coerce   => 1,
   required => 1,
);

#------------------------------------------------------------------------------
1;

__END__
