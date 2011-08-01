package Pinto::Event;

# ABSTRACT: Base class for events

use Moose;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has idxmgr => (
    is       => 'ro',
    isa      => 'Pinto::IndexManager',
    required => 1,
);


has message => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_message',
    default  => '',
    init_arg => undef,
);

#------------------------------------------------------------------------------
# Roles

with qw(Pinto::Role::Configurable Pinto::Role::Loggable);

#------------------------------------------------------------------------------
# Methods

sub execute { return 0 }

#------------------------------------------------------------------------------

1;

__END__
