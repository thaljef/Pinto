package Pinto::Server::Dispatch;

# ABSTRACT: URL dispatcher for the Pinto server

use Moose;

use base 'CGI::Application::Dispatch';

use Pinto::Server::Dispatch::Add;
#use Pinto::Server::Dispatch::Remove;
#use Pinto::Server::Dispatch::List;


use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has pinto => (
    is       => 'ro',
    isa      => 'Pinto',
    required => 1,
);

#-----------------------------------------------------------------------------

sub dispatch_args {
    my ($self) = @_;

    return {
        prefix      => 'Pinto::Server::Dispatch',
        args_to_new => { pinto => $self->pinto() },
        table       => [ 'add[post]' => {app => 'Add', rm => 'add'} ],
    };
}

#----------------------------------------------------------------------------

sub error_mode {
    return 'my_error_rm';
}

#----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#----------------------------------------------------------------------------
1;
