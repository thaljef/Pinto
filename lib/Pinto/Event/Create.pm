package Pinto::Event::Create;

# ABSTRACT: An event to create a new repository

use Moose;

use Carp;
use Path::Class;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # This event does not have to do anything, since the EventBatch
    # and Store will take care of making directories and generating
    # the initial index files for us.

    my $message = 'Created a new Pinto repository.';
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
