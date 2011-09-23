package Pinto::Role::UserAgent;

# ABSTRACT: Something that fetches remote files

use Moose::Role;

use Path::Class;
use LWP::UserAgent;

use Pinto::Exceptions qw(throw_fatal throw_error);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has _ua => (
    is       => 'ro',
    isa      => 'LWP::UserAgent',
    builder  => '_build_ua',
    init_arg => undef,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::PathMaker
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

=method fetch(url => 'http://someplace' to => 'some/path')

Fetches the file located at the C<url> to the file located at C<to>,
if the file at C<url> is newer than the file at C<to>.  If the
intervening directories do not exist, they will be created for you.
Returns a true value if the file has changed, returns false if it has
not changed.  Throws and exception if anything goes wrong.

=cut

sub fetch {
    my ($self, %args) = @_;

    my $url = URI->new($args{url})->canonical();
    my $to  = eval {$args{to}->isa('Path::Class')} ? $args{to} : file($args{to});

    $self->mkpath( $to->parent() );
    my $has_changed = $self->_fetch($url, $to);

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
    my $path = Path::Class::file( $url->path() );
    return $path if $url->scheme() eq 'file';

    my $base     = $path->basename();
    my $tempdir  = File::Temp::tempdir(CLEANUP => 1);
    my $tempfile = Path::Class::file($tempdir, $base);

    $self->fetch(url => $url, to => $tempfile);

    return Path::Class::file($tempfile);
}

#------------------------------------------------------------------------------

sub _fetch {
    my ($self, $url, $to) = @_;

    $self->info("Fetching $url");

    my $result = eval { $self->_ua->mirror($url, $to) } or throw_fatal $@;

    if ($result->is_success()) {
        return 1;
    }
    elsif ($result->code() == 304) {
        return 0;
    }
    else {
        throw_error "Failed to fetch $url: " . $result->status_line();
    }

    # Should never get here
}

#------------------------------------------------------------------------------

sub _build_ua {
    my ($self) = @_;

    # TODO: Do we need to make some of this configurable?
    my $agent = sprintf "%s/%s", ref $self, 'VERSION';
    my $ua = LWP::UserAgent->new( agent      => $agent,
                                  env_proxy  => 1,
                                  keep_alive => 5 );

    return $ua;
}

#------------------------------------------------------------------------------

1;

__END__
