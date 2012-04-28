# ABSTRACT: Base interface for Actions that alter the stack state of the repository.

package Pinto::Role::Interface::MutatorAction;

use Moose::Role;
use MooseX::Types::Moose qw(Str);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

requires qw(execute);

#------------------------------------------------------------------------------
# I want a contract that all MutatorActions will have a 'stack'
# attribute, but I don't want to dictate how that attribute will be
# realized.  I also want that contract expressed in a role so it can
# be shared between a Pinto::Action and a Pinto::Remote::Action
#
# The natural thing to do is to add 'stack' to the list of required
# methods for this role.  But that doesn't work because you cannot
# delay method requirements for a future subclass to implement it.  So
# the next best thing is to just provide an implementation here.  If a
# MutableAction wants to define the 'stack' differently, it can modify
# or override this method.
#
# The one pitfal is that there still isn't a contract that all
# MutableAction will have a 'stack'.  Since you can exclude
# attributes, it is possible to construct a class with MutableAction
# that does not have a 'stack'.  But I guess I'll have to live with
# that.
#
# In general, I'm not very happy with this.  I'd like to find a better
# way to define the interfaces that I need.

has stack => (
    is      => 'ro',
    isa     => Str,
    default => 'default',
);

#------------------------------------------------------------------------------

1;

__END__
