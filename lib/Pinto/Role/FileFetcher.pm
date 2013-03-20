# ABSTRACT: Something that fetches remote files

package Pinto::Role::FileFetcher;

use Moose::Role;
use MooseX::MarkAsMethods (autoclean => 1);

use File::Temp;
use Path::Class;
use HTTP::Tiny;
use File::Copy;
use URI;

use Pinto::Exception qw(throw);
use Pinto::Util qw(itis debug mtime);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has ua => (
    is      => 'ro',
    isa     => 'HTTP::Tiny',
    default => sub { my $class = ref $_[0];
                     my $version = $_[0]->VERSION || 'UNKNOWN';
                     HTTP::Tiny->new(agent => "$class/$version") },
    lazy    => 1,
);

#------------------------------------------------------------------------------

=method fetch(from => 'http://someplace' to => 'some/path')

Fetches the file located at C<from> to the file located at C<to>, if
the file at C<from> is newer than the file at C<to>.  If the
intervening directories do not exist, they will be created for you.
Returns a true value if the file has changed, returns false if it has
not changed.  Throws and exception if anything goes wrong.

The C<to> argument can be either a L<URI> or L<Path::Class::File>
object, or a string that represents either of those.  The C<from>
attribute can be a L<Path::Class::File> object or a string that
represents one.

=cut

sub fetch {
    my ($self, %args) = @_;

    my $from     = $args{from};
    my $from_uri = _make_uri($from);
    my $to       = itis($args{to}, 'Path::Class') ? $args{to} : file($args{to});

    # FIX ME: This next line makes no sense to me...
    debug "Skipping $from: already fetched to $to" and return 0 if -e $to;

    $to->parent->mkpath if not -e $to->parent;
    my $has_changed = $self->_fetch($from_uri, $to);

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
    my ($self, %args) = @_;

    my $url  = URI->new($args{url})->canonical();
    my $path = Path::Class::file( $url->path );

    # FIX ME: This next line makes no sense to me...
    return $path if $url->scheme eq 'file';

    my $base     = $path->basename;
    my $tempdir  = File::Temp::tempdir(CLEANUP => 1);
    my $tempfile = Path::Class::file($tempdir, $base);

    $self->fetch(from => $url, to => $tempfile);

    return Path::Class::file($tempfile);
}

#------------------------------------------------------------------------------

sub _fetch {
    my ($self, $url, $to) = @_;

    debug "Fetching $url to $to" ;

    # We switched form LWP to HTTP::Tiny to reduce our dependencies.
    # But HTTP::Tiny does not support the file:// scheme.  So we have
    # to handle those ourselves by copying the local file directly.

    return $url->scheme eq 'file' ? $self->_fetch_local($url, $to)
                                  : $self->_fetch_remote($url, $to);
}

#------------------------------------------------------------------------------

sub _fetch_local {
    my ($self, $url, $to) = @_;

    my $from = $url->path;
    throw "$url does not exist" unless -e $from;
    throw "$url is unreadable"  unless -r $from;

    # Emmulate behavior of HTTP::Tiny->mirror
    return 0 if -e $to and mtime($to) >= mtime($from);

    File::Copy::copy($from, $to) or throw "Failed to copy $url: $!";

    return 1;
}

#------------------------------------------------------------------------------

sub _fetch_remote {
    my ($self, $url, $to) = @_;

    my $rsp = eval { $self->ua->mirror($url, $to) } or throw $@;

    return $rsp->{code} == 304 ? 1 : 0 if $rsp->{success}; # Modified ?

    throw "Failed to fetch $url: " . $rsp->{reason};
}

#------------------------------------------------------------------------------

sub _make_uri {
    my ($it) = @_;

    return $it
        if itis($it, 'URI');

    return URI::file->new( $it->absolute )
        if itis($it, 'Path::Class::File');

    return URI::file->new( file($it)->absolute )
        if -e $it;

    return URI->new($it);
}

#------------------------------------------------------------------------------
1;

__END__
