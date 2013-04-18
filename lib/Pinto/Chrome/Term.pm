# ABSTRACT: Interface for terminal-based interaction

package Pinto::Chrome::Term;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool ArrayRef Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Term::ANSIColor 2.02 (); #First version with colorvalid()
use Term::EditorEdit;

use Pinto::Types qw(Io);
use Pinto::Util qw(user_colors is_interactive itis throw);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw( Pinto::Chrome );

#-----------------------------------------------------------------------------

has no_color => (
    is       => 'ro',
    isa      => Bool,
    default  => sub { return !!$ENV{PINTO_NO_COLOR} or 0 },
);


has colors => (
    is        => 'ro',
    isa       => ArrayRef,
    default   => sub { return user_colors },
    lazy      => 1,
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
    default => sub { [fileno(*STDERR), '>'] },
    coerce  => 1,
    lazy    => 1,
);


has diag_prefix => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

#-----------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my @colors = @{ $self->colors };

    throw "Must specify exactly three colors" if @colors != 3;

    Term::ANSIColor::colorvalid($_) || throw "Color $_ is not valid" for @colors;

    return $self;
};

#------------------------------------------------------------------------------

sub _build_stdout {
    my ($self) = @_;

    my $stdout = [fileno(*STDOUT), '>'];
    my $pager = $ENV{PINTO_PAGER} || $ENV{PAGER};

    return $stdout if not is_interactive;
    return $stdout if not $pager;

    open my $pager_fh, q<|->, $pager
        or throw "Failed to open pipe to pager $pager: $!";

    return bless $pager_fh, 'IO::Handle'; # HACK!
}

#------------------------------------------------------------------------------

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
    $msg =~ s/^/$self->diag_prefix/gemx if length $self->diag_prefix;

    print { $self->stderr } $msg or croak $!;
}

#-----------------------------------------------------------------------------

sub show_progress {
    my ($self) = @_;

    return if not $self->should_render_progress;

    $self->stderr->autoflush; # Make sure pipes are hot

    print {$self->stderr} '.' or croak $!;
}

#-----------------------------------------------------------------------------

sub progress_done {
    my ($self) = @_;

    return unless $self->should_render_progress;

    print {$self->stderr} "\n" or croak $!;
}

#-----------------------------------------------------------------------------

override should_render_progress => sub {
    my ($self) = @_;

    return 0 if not super;
    return 0 if not is_interactive;
    return 0 if not -t $self->stderr;
    return 1;
};

#-----------------------------------------------------------------------------

sub edit {
    my ($self, $document) = @_;

    local $ENV{VISUAL} = $ENV{PINTO_EDITOR} if $ENV{PINTO_EDITOR};

    # If this command is reading input from a pipe or file, then
    # STDIN will not be connected to a terminal.  This causes vim
    # and emacs to behave oddly (or even segfault).  After searching
    # the internets, this seems to a portable way to reconnect STDIN
    # to the actual terminal.  I haven't actually tried it on Windows.
    # I'm not sure if/how I should be localizing STDIN here.

    my $term = ($^O eq 'MSWin32') ? 'CON' : '/dev/tty';
    open(STDIN, '<', $term) or throw $!;

    return Term::EditorEdit->edit(document => $document);
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


