# ABSTRACT: Routes server requests

package Pinto::Server::Router;

use Moose;

use Scalar::Util;
use Plack::Request;
use Router::Simple;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

has route_handler => (
    is      => 'ro',
    isa     => 'Router::Simple',
    default => sub { Router::Simple->new },
);

#-------------------------------------------------------------------------------

sub BUILD {
  my ($self) = @_;

  my $r = $self->route_handler;

  $r->connect( '/action/{action}',
               {responder => 'Action'}, {method => 'POST'} );

  $r->connect( '/*',
               {responder => 'File'  }, {method => ['GET', 'HEAD'] } );

  return $self;
}

#-------------------------------------------------------------------------------

=method route( $env, $root )

Given the request environment and the path to the repository root,
dispatches the request to the appropriate responder and returns the
response.

=cut

sub route {
    my ($self, $env, $root) = @_;

    my $p = $self->route_handler->match($env)
      or return [404, [], ['Not Found']];

    my $responder_class = 'Pinto::Server::Responder::' . $p->{responder};
    Class::Load::load_class($responder_class);

    my $request   = Plack::Request->new($env);
    my $responder = $responder_class->new(request => $request, root => $root);

    # HACK: Plack-1.02 calls URI::Escape::uri_escape() with arguments
    # that inadvertently cause $_ to be compiled into a regex.  This
    # will emit warning if $_ is undef, or may blow up if it contains
    # certains stuff.  To avoid this, just make sure $_ is empty for
    # now.  A patch has been sent to Miyagawa.
    local $_ = '';

    return $responder->respond;
};

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords responder

=for Pod::Coverage BUILD

=cut
