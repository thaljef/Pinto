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

    my $local = Path::Class::dir($self->config()->get_required('local'));

    # croak "Repository already exists at $local" if -e $local;

    $local->mkpath( qw(authors id) );
    $local->mkpath( qw(modules) );
    # TODO: Generate empty indexes

    my $message = 'Created new repository';
    $self->_set_message($message);

    return $self;
}

#------------------------------------------------------------------------------

1;

__END__
