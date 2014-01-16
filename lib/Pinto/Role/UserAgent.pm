# ABSTRACT: Something that makes HTTP requests

package Pinto::Role::UserAgent;

use Moose::Role;
use MooseX::MarkAsMethods ( autoclean => 1 );

use URI;
use URI::file;
use Path::Class;
use LWP::UserAgent;

use Pinto::Globals;
use Pinto::Util qw(itis debug throw tempdir make_uri);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

=method fetch(from => 'http://someplace' to => 'some/path')

Fetches the file located at C<from> to the file located at C<to>, if
the file at C<from> is newer than the file at C<to>.  If the
intervening directories do not exist, they will be created for you.
Returns a true value if the file has changed, returns false if it has
not changed.  Throws and exception if anything goes wrong.

The C<from> argument can be either a L<URI> or L<Path::Class::File>
object, or a string that represents either of those.  The C<to>
attribute can be a L<Path::Class::File> object or a string that
represents one.

=cut

sub fetch {
    my ( $self, %args ) = @_;

    my $from     = $args{from};
    my $from_uri = make_uri($from);
    my $to       = itis( $args{to}, 'Path::Class' ) ? $args{to} : file( $args{to} );

    debug("Skipping $from: already fetched to $to") and return 0 if -e $to;

    $to->parent->mkpath if not -e $to->parent;
    my $has_changed = $self->_fetch( $from_uri, $to );

    return $has_changed;
}

#------------------------------------------------------------------------------

=method fetch_temporary(url => 'http://someplace')

Fetches the file located at the C<url> to a file in a temporary
directory.  The file will have the same basename as the C<url>.
Returns a L<Path::Class::File> that points to the new file.  Throws
and exception if anything goes wrong.  Note the temporary directory
and all its contents will be deleted when the process terminates.

=cut

sub fetch_temporary {
    my ( $self, %args ) = @_;

    my $url  = URI->new( $args{url} )->canonical;
    my $path = file( $url->path );
    return $path if $url->scheme() eq 'file';

    my $base     = $path->basename;
    my $tempfile = file( tempdir(), $base );

    $self->fetch( from => $url, to => $tempfile );

    return file($tempfile);
}

#------------------------------------------------------------------------------

sub head { 
    my $self = shift;

    return $Pinto::Globals::UA->head(@_);
}

#------------------------------------------------------------------------------
sub request {
    my $self = shift;

    return $Pinto::Globals::UA->request(@_);
}

#------------------------------------------------------------------------------

sub _fetch {
    my ( $self, $url, $to ) = @_;

    debug("Fetching $url");

    my $result = eval { $Pinto::Globals::UA->mirror( $url, $to ) }
        or throw $@;

    if ( $result->is_success() ) {
        return 1;
    }
    elsif ( $result->code() == 304 ) {
        return 0;
    }
    else {
        throw "Failed to fetch $url: " . $result->status_line;
    }

    # Should never get here
}

#-----------------------------------------------------------------------------
1;

__END__