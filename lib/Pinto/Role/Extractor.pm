package Pinto::Role::Extractor;

# ABSTRACT: Something that extracts packages

use Moose::Role;

use Pinto::Extractor;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has extractor => (
    is        => 'ro',
    isa       => 'Pinto::Extractor',
    builder   => '_build_extractor',
    lazy      => 1,
);

requires qw(logger config);

#------------------------------------------------------------------------------
# TODO: Allow users to specify an alternative extractor class in the config

#------------------------------------------------------------------------------
# Builders

sub _build_extractor {
    my ($self) = @_;

    return Pinto::Extractor->new( logger => $self->logger(),
                                  config => $self->config() );

}

#------------------------------------------------------------------------------
1;

__END__

