package Pinto::Action;

# ABSTRACT: Base class for Actions

use Moose;

use Carp;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has schema => (
    is       => 'ro',
    isa      => 'Pinto::Schema',
    required => 1,
);

has store => (
    is       => 'ro',
    isa      => 'Pinto::Store',
    required => 1,
);

has messages => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    traits     => [ 'Array' ],
    default    => sub{ [] },
    init_arg   => undef,
    handles    => {add_message => 'push'},
    auto_deref => 1,
);

has exceptions => (
    is         => 'ro',
    isa        => 'ArrayRef[Pinto::Exception]',
    traits     => [ 'Array' ],
    default    => sub{ [] },
    init_arg   => undef,
    handles    => {add_exception => 'push'},
    auto_deref => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;
    croak 'This is an absract method';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
