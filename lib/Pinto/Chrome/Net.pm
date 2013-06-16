# ABSTRACT: Interface for network-based interaction

package Pinto::Chrome::Net;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(Io);
use Pinto::Util qw(itis);
use Pinto::Constants qw(:server);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw( Pinto::Chrome::Term );

#-----------------------------------------------------------------------------

has stdout => (
    is       => 'ro',
    isa      => Io,
    required => 1,
    coerce   => 1,
);


has stderr => (
    is       => 'ro',
    isa      => Io,
    required => 1,
    coerce   => 1,
);

#-----------------------------------------------------------------------------

sub diag {
    my ($self, $msg, $opts) = @_;

    $opts ||= {};

    $msg = $msg->() if ref $msg eq 'CODE';

    if ( itis($msg, 'Pinto::Exception') ) {
        # Show full stack trace if we are debugging
        $msg = $ENV{PINTO_DEBUG} ? $msg->as_string : $msg->message;
    }

    chomp $msg;
    $msg  = $self->colorize($msg, $opts->{color});
    $msg .= "\n" unless $opts->{no_newline};

    # Prepend prefix to each line (not just at the start of the message)
    # The prefix is used by Pinto::Remote to distinguish between
    # messages that go to stderr and those that should go to stdout
    $msg =~ s/^/$PINTO_SERVER_DIAG_PREFIX/gmx;

    print { $self->stderr } $msg or croak $!;
}

#-----------------------------------------------------------------------------

sub show_progress {
    my ($self) = @_;

    return if not $self->should_render_progress;

    $self->stderr->autoflush; # Make sure pipes are hot

    print {$self->stderr} $PINTO_SERVER_PROGRESS_MESSAGE . "\n" or croak $!;
}

#-----------------------------------------------------------------------------

sub should_render_progress {
    my ($self) = @_;

    return 0 if $self->verbose;
    return 0 if $self->quiet;
    return 1;
};

#-----------------------------------------------------------------------------

sub edit {
    my ($self, $document) = @_;

    return $document; # TODO!
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__


