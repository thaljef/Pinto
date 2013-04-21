# ABSTRACT: Base class for responders

package Pinto::Server::Responder;

use Moose;

use Carp;

use Pinto::Types qw(Dir);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

has request => (
    is       => 'ro',
    isa      => 'Plack::Request',
    required => 1,
);


has root => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
);

#-------------------------------------------------------------------------------

=method respond( $request )

Given a L<Plack::Request>, responds with the appropriate
PSGI-compatible response.  This is an abstract method.  It is your job
to implement it in a concrete subclass.

=cut

sub respond { croak 'abstract method' }

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords responders

=cut
