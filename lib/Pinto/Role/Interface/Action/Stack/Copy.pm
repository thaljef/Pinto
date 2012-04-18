# ABSTRACT: Interface for Action::Stack::Create

package Pinto::Role::Interface::Action::Stack::Copy;

use Moose::Role;
use MooseX::Types::Moose qw(Str);

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action );

#------------------------------------------------------------------------------

has from_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);


has description => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_description',
);

#------------------------------------------------------------------------------

1;

__END__
