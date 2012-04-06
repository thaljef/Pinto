package Pinto::Logger;

# ABSTRACT: Writes log messages.

use Moose;
use MooseX::Types::Moose qw(Str);

use DateTime;
use Log::Dispatch;
use Log::Dispatch::File;

use Pinto::Types qw(Dir File);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Roles

with qw(Pinto::Interface::Configurable);

#-----------------------------------------------------------------------------
# Attributes

has log_level => (
    is      => 'ro',
    isa     => Str,
    default => sub { $_[0]->config->log_level },
);


has log_file => (
    is      => 'ro',
    isa     => File,
    default => sub { $_[0]->config->log_file },
    coerce  => 1,
);


has log_handler => (
    is       => 'ro',
    isa      => 'Log::Dispatch',
    builder  => '_build_log_handler',
    lazy     => 1,
    handles  => {
        debug => 'debug',
        note  => 'info',
        info  => 'notice',
        whine => 'warning',
        # fatal is handled below.
    },
);

#-----------------------------------------------------------------------------

sub _build_log_handler {
    my ($self) = @_;

    my $log_dir = $self->log_file->dir;
    $log_dir->mkpath if not -e $log_dir;

    my $log_filename = $self->log_file->stringify;

    my $cb = sub { my %args  = @_;
                   my $msg   = $args{message};
                   my $level = uc $args{level};
                   my $now   = DateTime->now->iso8601;
                   return "$now $level: $msg" };


    my $out = Log::Dispatch::File->new( min_level   => 'notice',
                                        filename    => $log_filename,
                                        mode        => 'append',
                                        permissions => 0644,
                                        callbacks   => $cb,
                                        newline     => 1 );

    my $handler = Log::Dispatch->new();
    $handler->add($out);

    return $handler;
}

#-----------------------------------------------------------------------------

=method add_output( $obj )

Adds the object to the output destinations that this logger writes to.
The object must be an instance of a L<Log::Dispatch::Output> subclass,
such as L<Log::Dispatch::Screen> or L<Log::Dispatch::Handle>.

=cut

sub add_output {
    my ($self, $output) = @_;

    my $base_class = 'Log::Dispatch::Output';
    $output->isa($base_class) or confess "Argument is not a $base_class";

    $self->log_handler->add($output);

    return $self;
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

    $self->log_handler->log_and_croak(level => 'fatal', message => $message);
}


#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
