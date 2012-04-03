package Pinto::Logger;

# ABSTRACT: A simple logger

use Moose;

use MooseX::Aliases;
use MooseX::Types::Moose qw(Int Bool Str);
use Pinto::Types qw(IO File);

use Readonly;
use Log::Dispatch;
use Log::Dispatch::Screen;
use Log::Dispatch::Screen::Color;
use Scalar::Util 'looks_like_number';
use List::Util qw(min max);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

# TODO: Const::Fast is much better
Readonly my $LEVEL_QUIET => -2;
Readonly my $LEVEL_WARN  => -1;
Readonly my $LEVEL_INFO  =>  0;
Readonly my $LEVEL_NOTE  =>  1;
Readonly my $LEVEL_DEBUG =>  2;

Readonly my %level_map => (
    -2  => 'critical',
    -1  => 'warn',
    0   => 'notice',    # info and notice appear in opposite order in LD.
    1   => 'info',
    2   => 'debug',      # this level or higher means "everything"
);

#-----------------------------------------------------------------------------
# Moose attributes

has log_level => (
    is      => 'ro',
    isa     => Str,
    default => 'notice',
    initializer => sub {
        my ($self, $value, $setter) = @_;
        my $level = looks_like_number($value)
            ? $level_map{min(max($value, -2), 2)}
            : $value;
        $setter->($level);
    },
);

# optionally logs to this filehandle
has filehandle => (
    is      => 'ro',
    isa     => IO,
    alias   => 'out', # for backcompat
    coerce  => 1,
    predicate => '_has_filehandle',
);

has noscreen => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { shift->_has_filehandle },
);

my %normal = ( text => undef, background => undef );
my %bold_yellow = ( text => 'yellow', background => undef, bold => 1 );
my %bold_red = ( text => 'red', background => undef, bold => 1 );

has log_handler => (
    is => 'rw',
    isa => 'Log::Dispatch',
    lazy => 1,
    default => sub {
        my $self = shift;
        Log::Dispatch->new(
            outputs => [
                ( $self->noscreen ? () : [
                    $self->nocolor ? 'Screen' : 'Screen::Color',
                    min_level => $self->log_level,
                    newline => 1,
                    color => { $self->nocolor ? () : (
                        info        => \%normal,
                        notice      => \%normal,
                        warning     => \%bold_yellow,
                        error       => \%bold_yellow,
                        critical    => \%bold_red,
                        alert       => \%bold_red,
                        emergency   => \%bold_red,
                        fatal       => \%bold_red,
                    )},
                ]),
                ( $self->filehandle ? [
                    'Handle',
                    min_level => $self->log_level,
                    newline => 1,
                    handle => $self->filehandle,
                ] : ()),
            ],
        );
    },
    handles => {
        debug => 'debug',
        note => 'info',         # info and notice appear in opposite order in LD.
        info => 'notice',
        whine => 'warning',
        # fatal is handled below.
    },
);

has nocolor => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

#-----------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    $args->{log_level} = delete $args->{verbose} if exists $args->{verbose};
    $args->{log_level} = 'critical' if delete $args->{quiet};

    return $args;
};

#-----------------------------------------------------------------------------
# Public methods

=method debug( $message )

Logs a message if C<verbose> is 1 or higher.

=method note( $message )

Logs a message if C<verbose> is 2 or higher.

=method info( $message )

Logs a message if C<verbose> is 0 or higher.

=method whine( $message )

Logs a message if C<verbose> is -1 or higher.

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
