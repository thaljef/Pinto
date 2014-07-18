# ABSTRACT: Responder for action requests

package Pinto::Server::Responder::Action;

use Moose;

use Carp;
use JSON;
use IO::Pipe;
use IO::Select;
use Try::Tiny;
use File::Temp;
use File::Copy;
use Proc::Fork;
use Path::Class;
use Proc::Terminator;
use Plack::Response;
use HTTP::Status qw(:constants);

use Pinto;
use Pinto::Result;
use Pinto::Chrome::Net;
use Pinto::Constants qw(:protocol);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

extends qw(Pinto::Server::Responder);

#-------------------------------------------------------------------------------

sub respond {
    my ($self) = @_;

    my $error_response = $self->check_protocol_version;
    return $error_response if $error_response;

    # path_info always has a leading slash, e.g. /action/list
    my ( undef, undef, $action_name ) = split '/', $self->request->path_info;

    my %params      = %{ $self->request->parameters };                         # Copying
    my $chrome_args = $params{chrome} ? decode_json( $params{chrome} ) : {};
    my $pinto_args  = $params{pinto}  ? decode_json( $params{pinto} )  : {};
    my $action_args = $params{action} ? decode_json( $params{action} ) : {};

    for my $upload_name ( $self->request->uploads->keys ) {
        my $upload    = $self->request->uploads->{$upload_name};
        my $basename  = $upload->filename;
        my $localfile = file( $upload->path )->dir->file($basename);
        File::Copy::move( $upload->path, $localfile );                         #TODO: autodie
        $action_args->{$upload_name} = $localfile;
    }

    my $response;
    my $pipe = IO::Pipe->new;

    run_fork {
        child  { $self->child_proc( $pipe, $chrome_args, $pinto_args, $action_name, $action_args ) }
        parent { my $child_pid = shift; $response = $self->parent_proc( $pipe, $child_pid ) }
        error  { croak "Failed to fork: $!" };
    };

    return $response;
}

#-------------------------------------------------------------------------------

sub check_protocol_version {
    my ($self) = @_;

    # NB: Format derived from GitHub: https://developer.github.com/v3/media
    my $media_type_rx = qr{^ application / vnd [.] pinto [.] v(\d+) (?:[+] .+)? $}ix;

    my $accept = $self->request->header('Accept') || '';
    my $version = $accept =~ $media_type_rx ? $1 : 0;

    return unless my $cmp = $version <=> $PINTO_PROTOCOL_VERSION;

    my $fmt = 'Your client is too %s for this server. You must upgrade %s.';
    my ($age, $component) = $cmp > 0 ? qw(new pintod) : qw(old pinto);
    my $msg = sprintf $fmt, $age, $component;

    return [ HTTP_UNSUPPORTED_MEDIA_TYPE, [], [$msg] ];
}

#-------------------------------------------------------------------------------

sub child_proc {
    my ( $self, $pipe, $chrome_args, $pinto_args, $action_name, $action_args ) = @_;

    my $writer = $pipe->writer;
    $writer->autoflush;

    # I'm not sure why, but cleanup isn't happening when we get
    # a TERM signal from the parent process.  I suspect it
    # has something to do with File::NFSLock messing with %SIG
    local $SIG{TERM} = sub { File::Temp::cleanup; die $@ };

    ## no critic qw(PackageVar)
    local $Pinto::Globals::current_username    = delete $pinto_args->{username};
    local $Pinto::Globals::current_time_offset = delete $pinto_args->{time_offset};
    ## use critic;

    $chrome_args->{stdout} = $writer;
    $chrome_args->{stderr} = $writer;

    my $chrome = Pinto::Chrome::Net->new($chrome_args);
    my $pinto = Pinto->new( chrome => $chrome, root => $self->root );

    my $result =
        try   { $pinto->run( ucfirst $action_name => %{$action_args} ) }
        catch { print {$writer} $_; Pinto::Result->new->failed };

    print {$writer} $PINTO_PROTOCOL_STATUS_OK . "\n" if $result->was_successful;

    exit $result->was_successful ? 0 : 1;
}

#-------------------------------------------------------------------------------

sub parent_proc {
    my ( $self, $pipe, $child_pid ) = @_;

    my $reader = $pipe->reader;
    my $select = IO::Select->new($reader);
    $reader->blocking(0);

    my $response = sub {
        my $responder = shift;

        my $headers   = ['Content-Type' => 'text/plain'];
        my $writer    = $responder->( [ HTTP_OK, $headers ] );
        my $socket    = $self->request->env->{'psgix.io'};
        my $nullmsg   = $PINTO_PROTOCOL_NULL_MESSAGE . "\n";


        while (1) {

            my $input;
            if ( $select->can_read(1) ) {
                $input = <$reader>;    # Will block until \n
                last if not defined $input;    # We reached eof
            }

            my $ok = eval {
                local $SIG{ALRM} = sub { die "Write timed out" };
                alarm(3);

                $writer->write( $input || $nullmsg );
                1;                             # Write succeeded
            };

            alarm(0);
            unless ( $ok && ( !$socket || getpeername($socket) ) ) {
                proc_terminate( $child_pid, max_wait => 10 );
                last;
            }
        }

        $writer->close if not $socket;         # Hangs otherwise!
        waitpid $child_pid, 0;
    };

    return $response;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;
