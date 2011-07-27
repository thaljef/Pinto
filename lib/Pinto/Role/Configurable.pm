package Pinto::Role::Configurable;

# ABSTRACT: Something that has a configuration

use Moose::Role;

use Pinto::Config;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has config => (
    is       => 'ro',
    isa      => 'Pinto::Config',
    default  => sub { Pinto::Config->instance() },
);

#-----------------------------------------------------------------------------

1;

__END__
