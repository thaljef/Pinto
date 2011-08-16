package Pinto::Server;

# ABSTRACT: Web interface to a Pinto repository
use Moose;

use CGI::Application::Server;

use Pinto;
use Pinto::Logger;
use Pinto::Server::Dispatch;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

with qw( MooseX::Daemonize );

#-----------------------------------------------------------------------------

has config   => (
    is       => 'ro',
    isa      => 'Pinto::Server::Config',
    required => 1,
);


has '+pidbase' => (
    default  => sub { $_[0]->config->config_file->dir() },
);

#-----------------------------------------------------------------------------

after start => sub {
    my $self = shift;
    return unless $self->is_daemon();

    my $server = CGI::Application::Server->new( $self->config->port() );
    $server->document_root( $self->config->local() );

    my $logger = Pinto::Logger->new( config => $self->config() );
    my $pinto = Pinto->new( config => $self->config(), logger => $logger );
    my $dispatch = Pinto::Server::Dispatch->new( pinto => $pinto );
    $server->entry_points( {'/action' => $dispatch} );

    return $server->run();
};

#----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#----------------------------------------------------------------------------
1;

__END__
