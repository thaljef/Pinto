package Pinto::Server::Dispatch;

# ABSTRACT: Dispatch table for a Pinto server

use strict;
use warnings;

use base 'CGI::Application::Dispatch';

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub dispatch_args {
    return {
        table => [ 'add[post]' => {app => 'Pinto::Server', rm => 'add'} ],
    };
}

#----------------------------------------------------------------------------
1;
