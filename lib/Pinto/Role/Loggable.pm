package Pinto::Role::Loggable;

# ABSTRACT: Something that wants to log its activity

use Moose::Role;

use Pinto::Logger;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has logger => (
    is       => 'ro',
    isa      => 'Pinto::Logger',
    default  => sub { Pinto::Logger->instance() },
);

#-----------------------------------------------------------------------------

1;

__END__
