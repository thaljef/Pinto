package Pinto::Action;

# ABSTRACT: Base class for Actions

use Moose;
use Moose::Autobox;

use Carp;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has idxmgr => (
    is       => 'ro',
    isa      => 'Pinto::IndexManager',
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
    default    => sub{ [] },
    init_arg   => undef,
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

sub add_message {
    my ($self, @messages) = @_;

    $self->messages()->push( @messages );

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
