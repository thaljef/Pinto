package Pinto::Action;

# ABSTRACT: Base class for Actions

use Moose;

use Carp;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has repos => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);

has messages => (
    isa        => 'ArrayRef[Str]',
    traits     => [ 'Array' ],
    handles    => {
        add_message => 'push',
        messages    => 'elements',
    },
    default    => sub{ [] },
    init_arg   => undef,
);

has exceptions => (
    isa        => 'ArrayRef[Pinto::Exception]',
    traits     => [ 'Array' ],
    default    => sub{ [] },
    init_arg   => undef,
    handles    => {
        add_exception => 'push',
        exceptions    => 'elements',
    },
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
