# ABSTRACT: Web interface to a Pinto repository

package Pinto::Server;

use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::Moose qw(Int HashRef ArrayRef);

use Carp;
use Path::Class;
use Class::Load;
use Scalar::Util qw(blessed);
use IO::Interactive qw(is_interactive);
use Plack::Middleware::Auth::Basic;
use Plack::App::URLMap;

use Pinto::Types qw(Dir);
use Pinto::Constants qw(:server);
use Pinto::Server::Router;
use Pinto::Repository;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

=attr root

The path to the root directory of your Pinto repository.  The
repository must already exist at this location.  This attribute is
required.

=cut

has root => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

=attr auth

The hashref of authentication options, if authentication is to be used within
the server. One of the options must be 'backend', to specify which
Authen::Simple:: class to use; the other key/value pairs will be passed as-is
to the Authen::Simple class.

=cut

has auth => (
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    handles => { auth_options => 'elements' },
);

=attr skip_auth

The arrayref of actions that allow passwordless access.

=cut

has skip_auth => (
    is      => 'ro',
    isa     => ArrayRef,
#    default => sub { ['list', 'roots'] },
);


=attr router

An object that does the L<Pinto::Server::Handler> role.  This object
will do the work of processing the request and returning a response.

=cut

has router => (
    is      => 'ro',
    isa     => 'Pinto::Server::Router',
    default => sub { Pinto::Server::Router->new },
    lazy    => 1,
);

=attr default_port

Returns the default port number that the server will listen on.  This
is a class attribute.

=cut

class_has default_port => (
    is      => 'ro',
    isa     => Int,
    default => $PINTO_SERVER_DEFAULT_PORT,
);

#-------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $repo = Pinto::Repository->new( root => $self->root );
    $repo->assert_sanity_ok;

    return $self;
}

#-------------------------------------------------------------------------------

=method to_app()

Returns the application as a subroutine reference.

=cut

sub to_app {
    my ($self) = @_;

    my $app = sub {
	my $env = $_[0];
	# Plack::App::URLMap does some stuff to path info which we need to undo
	$env->{PATH_INFO} = $env->{SCRIPT_NAME}.$env->{PATH_INFO};
	$env->{SCRIPT_NAME} = '';
	$self->call(@_);
    };

    if ( my %auth_options = $self->auth_options ) {

        my $backend = delete $auth_options{backend}
            or carp 'No auth backend provided!';

        my $class = 'Authen::Simple::' . $backend;
        print "Authenticating using $class\n" if is_interactive;
        Class::Load::load_class($class);
	my $authenticated_app = Plack::Middleware::Auth::Basic->wrap(
	    $app, authenticator => $class->new(%auth_options));
	if(@{$self->skip_auth}) {
	    my $urlmap = Plack::App::URLMap->new;
	    $urlmap->map("/" => $authenticated_app);
	    foreach (@{$self->skip_auth}) {
		$urlmap->map('/action/'.$_ => $app);
	    }
	    $app = $urlmap->to_app;
	} else {
	    $app = $authenticated_app;
	}
    }

    return $app;
}

#-------------------------------------------------------------------------------

=method call( $env )

Invokes the application with the specified environment.  Returns a
PSGI-compatible response.

=cut

sub call {
    my ( $self, $env ) = @_;

    my $response = $self->router->route( $env, $self->root );

    $response = $response->finalize
        if blessed($response) && $response->can('finalize');

    return $response;
}

#-------------------------------------------------------------------------------
1;

__END__

=pod

There is nothing to see here.

Look at L<pintod> if you want to start the server.

=cut


