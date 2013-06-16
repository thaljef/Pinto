# ABSTRACT: Interface for network-based interaction

package Pinto::Chrome::Net;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool ArrayRef Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Term::EditorEdit;

use Pinto::Types qw(Io ANSIColorSet);
use Pinto::Constants qw(:server);
use Pinto::Util qw(user_colors is_interactive itis throw);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw( Pinto::Chrome );

#-----------------------------------------------------------------------------

has no_color => (
    is       => 'ro',
    isa      => Bool,
    default  => sub { !!$ENV{PINTO_NO_COLOR} || 0 },
);


has colors => (
    is        => 'ro',
    isa       => ArrayRef,
    default   => sub { user_colors() },
    lazy      => 1,
);


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

sub show { 
    my ($self, $msg, $opts) = @_;

    $opts ||= {};

    $msg = $self->colorize($msg, $opts->{color});

    $msg .= "\n" unless $opts->{no_newline};

    print { $self->stdout } $msg or croak $!;

    return $self
}

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

sub progress_done {
    my ($self) = @_;

    return unless $self->should_render_progress;

    print {$self->stderr} "\n" or croak $!;
}

#-----------------------------------------------------------------------------

sub edit {
    my ($self, $document) = @_;

    return $document; # TODO!
}

#-----------------------------------------------------------------------------

sub colorize {
    my ($self, $string, $color_number) = @_;

    return ''      if not $string;
    return $string if not defined $color_number;
    return $string if $self->no_color;

    my $color = $self->get_color($color_number);

    return $color . $string . Term::ANSIColor::color('reset');
}

#-----------------------------------------------------------------------------

sub get_color {
    my ($self, $color_number) = @_;

    return '' if not defined $color_number;

    my $color = $self->colors->[$color_number];

    throw "Invalid color number: $color_number" if not defined $color;

    return Term::ANSIColor::color($color);
}

#-----------------------------------------------------------------------------

my %color_map = (warning => 1, error => 2);
while ( my ($level, $color) = each %color_map)  {
    around $level => sub {
        my ($orig, $self, $msg, $opts) = @_;
        $opts ||= {}; $opts->{color} = $color;
        return $self->$orig($msg, $opts); 
    }; 
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__


