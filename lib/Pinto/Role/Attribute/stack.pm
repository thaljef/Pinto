# ABSTRACT: Something that has a stack attribute

package Pinto::Role::Attribute::stack;

use Moose::Role;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Meta::Attribute::Trait::Postable );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName,
    traits   => [ qw(Postable) ],
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------
1;

__END__
