package Pinto::Event::Create;

# ABSTRACT: An event to create a new repository

use Moose;

use Carp;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;
    # TODO: Generate empty indexes
    # TODO: Create some directory structure in repository
    my $message = 'Created new repository';
    $self->_set_message($message);
}

#------------------------------------------------------------------------------

1;

__END__
