package Pinto::Logger;

# ABSTRACT: A simple logger

use Moose;
use MooseX::Aliases;
use MooseX::Types::Moose qw(HashRef Int Bool Str);

use Readonly;
use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Handle;
use Log::Dispatch::Screen;
use Log::Dispatch::Screen::Color;
use List::Util qw(min max);
use DateTime;

use Pinto::Types qw(IO File);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

Readonly my %level_map => (
    -2   => 'critical',
    -1   => 'warn',
     0   => 'notice',    # info and notice appear in opposite order in LD.
     1   => 'info',
     2   => 'debug',     # this level or higher means "everything"
);

#-----------------------------------------------------------------------------

my $COLOR_NORMAL      = { text => undef,    background => undef };
my $COLOR_BOLD_YELLOW = { text => 'yellow', background => undef, bold => 1 };
my $COLOR_BOLD_RED    = { text => 'red',    background => undef, bold => 1 };

#-----------------------------------------------------------------------------
# Roles

with qw(Pinto::Interface::Configurable);

#-----------------------------------------------------------------------------
# Attributes

has log_level => (
    is      => 'ro',
    isa     => Str,
    default => 'notice',
);


has log_file => (
    is      => 'ro',
    isa     => File,
    default => sub { $_[0]->config->log_file },
    coerce  => 1,
);


has out => (
    is      => 'ro',
    isa     => IO,
    coerce  => 1,
);


has out_prefix  => (
    is       => 'ro',
    isa      => Str,
    default  => '',
);


has nocolor => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);


has noscreen => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);


has colors  => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {{
        info        => $COLOR_NORMAL,
        notice      => $COLOR_NORMAL,
        warning     => $COLOR_BOLD_YELLOW,
        error       => $COLOR_BOLD_YELLOW,
    }},
);


has log_handler => (
    is       => 'rw',
    isa      => 'Log::Dispatch',
    lazy     => 1,
    builder  => '_build_log_handler',
    handles  => {
        debug => 'debug',
        note  => 'info',
        info  => 'notice',
        whine => 'warning',
        # fatal is handled below.
    },
);

#-----------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    # Translate numeric verbosity to a named log level.  If you
    # specified an explicit log_level, then it has priority.

    if (my $verbose = delete $args->{verbose}) {
        $verbose = min(max($verbose, -2), 2);
        $args->{log_level} ||= $level_map{$verbose};
    };

    $args->{log_level} = 'critical' if delete $args->{quiet};

    return $args;
};

#-----------------------------------------------------------------------------

sub _build_log_handler {
    my ($self) = @_;

    my $log_dir = $self->config->log_dir;
    $log_dir->mkpath if not -e $log_dir;

    my $log = Log::Dispatch->new();

    #-----------------------------
    # Repository log file...

    my $type = 'Log::Dispatch::File';

    my $cb = sub { my %args = @_;
                   return DateTime->now->iso8601 . uc(" $args{level}: ") . $args{message} };

    $log->add( $type->new(min_level   => 'notice',
                          filename    => $self->log_file->stringify,
                          mode        => 'append',
                          permissions => 0644,
                          callbacks   => [ $cb ],
                          newline     => 1) );


    #-----------------------------
    # The terminal...

    unless ($self->noscreen) {

        my $type = 'Log::Dispatch::Screen';
        $type   .= '::Color' unless $self->nocolor;

        my $colors  = $self->nocolor ? {} : $self->colors;

        $log->add( $type->new(min_level => $self->log_level,
                              color     => $colors,
                              stderr    => 1,
                              newline   => 1) );
    }


    #-----------------------------
    # Output handle to client...

    if ($self->out) {
        my $type = 'Log::Dispatch::Handle';

        my $cb = sub { my %args = @_;
                       return $self->out_prefix . $args{message} };

        $log->add( $type->new(min_level => $self->log_level,
                              handle    => $self->out,
                              callbacks => [ $cb ],
                              newline   => 1) );
    }

    return $log;
}

#-----------------------------------------------------------------------------

=method debug( $message )

Logs a message if C<verbose> is 1 or higher.

=method note( $message )

Logs a message if C<verbose> is 2 or higher.

=method info( $message )

Logs a message if C<verbose> is 0 or higher.

=method whine( $message )

Logs a message to C<verbose> is -1 or higher.

=method fatal( $message )

Dies with the given message.

=cut

sub fatal {
    my ($self, $message) = @_;

    $self->log_handler->log_and_die(level => 'fatal', message => $message);
}


#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
