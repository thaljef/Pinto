# ABSTRACT: Interface for terminal-based interaction

package Pinto::Chrome::Term;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool ArrayRef Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Term::ANSIColor;
use Term::EditorEdit;
use File::Which qw(which);

use Pinto::Types qw(Io ANSIColorSet);
use Pinto::Util qw(user_colors itis throw is_interactive);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw( Pinto::Chrome );

#-----------------------------------------------------------------------------

has no_color => (
    is      => 'ro',
    isa     => Bool,
    default => sub { !!$ENV{PINTO_NO_COLOR} || 0 },
);

has colors => (
    is      => 'ro',
    isa     => ANSIColorSet,
    default => sub { user_colors() },
    lazy    => 1,
);

has stdout => (
    is      => 'ro',
    isa     => Io,
    builder => '_build_stdout',
    coerce  => 1,
    lazy    => 1,
);

has stderr => (
    is      => 'ro',
    isa     => Io,
    default => sub { [ fileno(*STDERR), '>' ] },
    coerce  => 1,
    lazy    => 1,
);

#-----------------------------------------------------------------------------

sub _build_stdout {
    my ($self) = @_;

    my $pager = $ENV{PINTO_PAGER} || $ENV{PAGER};
    my $stdout = [ fileno(*STDOUT), '>' ];

    return $stdout if not -t STDOUT;
    return $stdout if not $pager;

    open my $pager_fh, q<|->, $pager
        or throw "Failed to open pipe to pager $pager: $!";

    return bless $pager_fh, 'IO::Handle';    # HACK!
}

#------------------------------------------------------------------------------

sub show {
    my ( $self, $msg, $opts ) = @_;

    $opts ||= {};

    $msg = $self->colorize( $msg, $opts->{color} );

    $msg .= "\n" unless $opts->{no_newline};

    print { $self->stdout } $msg or croak $!;

    return $self;
}

#-----------------------------------------------------------------------------

sub diag {
    my ( $self, $msg, $opts ) = @_;

    $opts ||= {};

    return if $self->quiet;

    $msg = $msg->() if ref $msg eq 'CODE';

    if ( itis( $msg, 'Pinto::Exception' ) ) {

        # Show full stack trace if we are debugging
        $msg = $ENV{PINTO_DEBUG} ? $msg->as_string : $msg->message;
    }

    chomp $msg;
    $msg = $self->colorize( $msg, $opts->{color} );
    $msg .= "\n" unless $opts->{no_newline};

    print { $self->stderr } $msg or croak $!;
}

#-----------------------------------------------------------------------------

sub show_progress {
    my ($self) = @_;

    return if not $self->should_render_progress;

    $self->stderr->autoflush;    # Make sure pipes are hot

    print { $self->stderr } '.' or croak $!;
}

#-----------------------------------------------------------------------------

sub progress_done {
    my ($self) = @_;

    return unless $self->should_render_progress;

    print { $self->stderr } "\n" or croak $!;
}

#-----------------------------------------------------------------------------

sub should_render_progress {
    my ($self) = @_;

    return 0 if $self->verbose;
    return 0 if $self->quiet;
    return 0 if not is_interactive;
    return 1;
}

#-----------------------------------------------------------------------------

sub edit {
    my ( $self, $document ) = @_;

    local $ENV{VISUAL} = $self->find_editor
        or throw 'Unable to find an editor.  Please set PINTO_EDITOR';

    # If this command is reading input from a pipe or file, then
    # STDIN will not be connected to a terminal.  This causes vim
    # and emacs to behave oddly (or even segfault).  After searching
    # the internets, this seems to a portable way to reconnect STDIN
    # to the actual terminal.  I haven't actually tried it on Windows.
    # I'm not sure if/how I should be localizing STDIN here.

    my $term = ( $^O eq 'MSWin32' ) ? 'CON' : '/dev/tty';
    open( STDIN, '<', $term ) or throw $!;

    return Term::EditorEdit->edit( document => $document );
}

#-----------------------------------------------------------------------------

sub colorize {
    my ( $self, $string, $color_number ) = @_;

    return ''      if not $string;
    return $string if not defined $color_number;
    return $string if $self->no_color;

    my $color = $self->get_color($color_number);

    return $color . $string . Term::ANSIColor::color('reset');
}

#-----------------------------------------------------------------------------

sub get_color {
    my ( $self, $color_number ) = @_;

    return '' if not defined $color_number;

    my $color = $self->colors->[$color_number];

    throw "Invalid color number: $color_number" if not defined $color;

    return Term::ANSIColor::color($color);
}

#-----------------------------------------------------------------------------

sub find_editor {
    my ($self) = @_;

    # Try unsing environment variables first
    for my $env_var (qw(PINTO_EDITOR VISUAL EDITOR)) {
        return $ENV{$env_var} if $ENV{$env_var};
    }

    # Then try typical editor commands
    for my $cmd (qw(nano pico vi)) {
        my $found_cmd = which($cmd);
        return $found_cmd if $found_cmd;
    }

    return;
}

#-----------------------------------------------------------------------------

my %color_map = ( warning => 1, error => 2 );
while ( my ( $level, $color ) = each %color_map ) {
    around $level => sub {
        my ( $orig, $self, $msg, $opts ) = @_;
        $opts ||= {};
        $opts->{color} = $color;
        return $self->$orig( $msg, $opts );
    };
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__


