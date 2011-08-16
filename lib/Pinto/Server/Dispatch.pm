package Pinto::Server::Dispatch;

# ABSTRACT: URL dispatcher for the Pinto server

use Pinto;
use Pinto::Logger;
use Pinto::Server::Config;

use Pinto::Server::Dispatch::Add;
#use Pinto::Server::Dispatch::Remove;
#use Pinto::Server::Dispatch::List;

use base 'CGI::Application::Dispatch::PSGI';

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

my $config = Pinto::Server::Config->new();
my $logger = Pinto::Logger->new(config => $config);
my $pinto  = Pinto->new(config => $config, logger => $logger);

#-----------------------------------------------------------------------------

sub dispatch_args {

    return {
        prefix      => 'Pinto::Server::Dispatch',
        args_to_new => { pinto => $pinto },
        table       => [ 'add[post]' => {app => 'Add', rm => 'add'} ],
    };
}

#----------------------------------------------------------------------------

1;
