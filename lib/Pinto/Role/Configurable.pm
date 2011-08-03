package Pinto::Role::Configurable;

# ABSTRACT: Something that has a configuration

use Moose::Role;

use Pinto::Config;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has config => (
    is         => 'ro',
    isa        => 'Pinto::Config',
    lazy_build => 1,
);


sub _build_config {
    return Pinto::Config->new();
}

#-----------------------------------------------------------------------------

1;

__END__
