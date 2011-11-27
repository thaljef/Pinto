package Pinto::Extractor;

# ABSTRACT: Base class for extractors

use Moose;

use Carp;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Loggable
         Pinto::Interface::Configurable );

#-----------------------------------------------------------------------------

sub extract { croak 'Abstract method' };

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
