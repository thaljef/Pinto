package Pinto::Interface::Loggable;

# ABSTRACT: Something that wants to log its activity

use Moose::Role;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has logger => (
    is         => 'ro',
    isa        => 'Pinto::Logger',
    handles    => [ qw(debug note info whine fatal) ],
    required   => 1,
);

#-----------------------------------------------------------------------------

1;

__END__
