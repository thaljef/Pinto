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

=method mirror(RESOURCE => PATH)

Mirrors the resource located at C<from> to the file located at PATH, if the
RESOURCE is newer than the file at PATH.  If the intervening directories do
not exist, they will be created for you. Returns a true value if the file has
changed, returns false if it has not changed.  Throws an exception if anything
goes wrong.

The RESOURCE can be either a L<URI> or L<Path::Class::File> object, or a
string that represents either of those.  The PATH can be a
L<Path::Class::File> object or a string that represents one.

=cut

sub mirror {
    my ( $self, $from, $to ) = @_;

    $from = make_uri($from);
    $to = file($to);

    $to->parent->mkpath if not -e $to->parent;
    my $response = $Pinto::Globals::UA->mirror( $from => $to );
    
    return 1 if $response->is_success;
    return 0 if $response->code == HTTP_NOT_MODIFIED;

    throw "Failed to mirror $from: " . $response->status_line;
}

#------------------------------------------------------------------------------

=method mirror_temporary(RESOURCE)

Mirrors RESOURCE to a file in a temporary directory.  The file will have the
same basename as the RESOURCE.  Returns a L<Path::Class::File> that points to
the new file.  Throws and exception if anything goes wrong.  Note the
temporary directory and all its contents will be deleted when the process
terminates.

=cut

sub mirror_temporary {
    my ( $self, $uri ) = @_;

    $uri  = URI->new( $uri )->canonical;
    my $path = file( $uri->path );
    return $path if $uri->scheme() eq 'file';

    my $base     = $path->basename;
    my $tempfile = file( tempdir, $base );

    $self->mirror( $uri => $tempfile );

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