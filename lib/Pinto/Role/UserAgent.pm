# ABSTRACT: Something that makes network requests

package Pinto::Role::UserAgent;

use Moose::Role;
use MooseX::MarkAsMethods ( autoclean => 1 );

use URI;
use Path::Class;
use LWP::UserAgent;
use HTTP::Status qw(:constants);

use Pinto::Globals;
use Pinto::Util qw(debug throw tempdir make_uri);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# TODO: Better interface: mirror( $here => $there );

=method fetch(from => 'http://something' to => 'some/path')

Fetches the resource located at C<from> to the file located at C<to>, if the
resource at C<from> is newer than the file at C<to>.  If the intervening
directories do not exist, they will be created for you. Returns a true value
if the file has changed, returns false if it has not changed.  Throws an
exception if anything goes wrong.

The C<from> argument can be either a L<URI> or L<Path::Class::File> object, or
a string that represents either of those.  The C<to> attribute can be a
L<Path::Class::File> object or a string that represents one.

=cut

sub fetch {
    my ( $self, %args ) = @_;

    my $from = $args{from};
    my $uri  = make_uri($from);
    my $to   = file( $args{to} );

    debug("Skipping $from: already fetched to $to") and return 0 if -e $to;

    $to->parent->mkpath if not -e $to->parent;
    my $result = eval { $Pinto::Globals::UA->mirror( $uri, $to ) };
    
    throw $@ if $@;

    return 1 if $result->is_success;
    return 0 if $result->code == HTTP_NOT_MODIFIED;

    throw "Failed to fetch $uri: " . $result->status_line;
}

#------------------------------------------------------------------------------
# TODO: Better interface: mirror_temporary($here);

=method fetch_temporary(uri => 'http://someplace')

Fetches the resource located at the C<uri> to a file in a temporary directory.
The file will have the same basename as the C<uri>. Returns a
L<Path::Class::File> that points to the new file.  Throws and exception if
anything goes wrong.  Note the temporary directory and all its contents will
be deleted when the process terminates.

=cut

sub fetch_temporary {
    my ( $self, %args ) = @_;

    my $uri  = URI->new( $args{uri} )->canonical;
    my $path = file( $uri->path );
    return $path if $uri->scheme() eq 'file';

    my $base     = $path->basename;
    my $tempfile = file( tempdir, $base );

    $self->fetch( from => $uri, to => $tempfile );

    return file($tempfile);
}

#------------------------------------------------------------------------------
# TODO: Consider a better interface to the UA

sub head { 
    my ($self, @args) = @_;

    # TODO: Argument check?
    debug sub { $args[0]->as_string(0) };
    return $Pinto::Globals::UA->head(@args);
}

#------------------------------------------------------------------------------
# TODO: Consider a better interface to the UA

sub request {
    my ($self, @args) = @_;

    # TODO: Argument check?
    debug sub { $args[0]->as_string(0) };
    return $Pinto::Globals::UA->request(@args);
}

#-----------------------------------------------------------------------------
1;

__END__