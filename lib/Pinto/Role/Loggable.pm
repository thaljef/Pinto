package Pinto::Role::Loggable;

# ABSTRACT: Something that wants to log its activity

use Moose::Role;

use Pinto::Logger;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has logger => (
    is         => 'ro',
    isa        => 'Pinto::Logger',
    lazy_build => 1,
);


sub _build_logger {
    return Pinto::Logger->new();
}

#-----------------------------------------------------------------------------

1;

__END__
