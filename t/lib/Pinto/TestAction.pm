package Pinto::TestAction;

# ABSTRACT: A no-op Action used for testing Pinto

use Moose;
use MooseX::Types::Moose qw(Int CodeRef);

extends qw(Pinto::Action);

#-----------------------------------------------------------------------------

has callback => (
   is      => 'ro',
   isa     => CodeRef,
   default => sub { sub{} },
);

has return => (
   is      => 'ro',
   isa     => Int,
   default => 0,
);

#-----------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;
    $self->callback->();  # TODO: should we pass something here?
    return $self->return();
};

#-----------------------------------------------------------------------------
