package Pinto::Action;

# ABSTRACT: Base class for all Actions

use Moose;

use Pinto::ActionResult;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

has repos => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);


has result => (
    is       => 'ro',
    isa      => 'Pinto::ActionResult',
    default  => sub { Pinto::ActionResult->new },
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
