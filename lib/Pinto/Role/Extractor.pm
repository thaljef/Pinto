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


#------------------------------------------------------------------------------
# TODO: Allow users to specify an alternative extractor class in the config

#------------------------------------------------------------------------------
# Builders

sub _build_extractor {
    my ($self) = @_;


}

#------------------------------------------------------------------------------
1;

__END__

