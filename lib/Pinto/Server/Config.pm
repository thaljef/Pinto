package Pinto::Server::Config;

# ABSTRACT: Configuration for Pinto::Server

use Moose;
use MooseX::Types::Moose qw(Int);

use namespace::autoclean;

extends 'Pinto::Config';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has 'port'   => (
    is        => 'ro',
    isa       => Int,
    key       => 'port',
    section   => 'Pinto::Server',
    default   => 1973,
);

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
