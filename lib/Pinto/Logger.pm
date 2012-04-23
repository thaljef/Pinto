# ABSTRACT: Record events in the repository log file (and elsewhere).

package Pinto::Logger;

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

with qw(Pinto::Role::Configurable);

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
    handles  => [qw(debug info notice warning error)], # fatal is handled below
    lazy     => 1,
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
    $output->isa($base_class) or $self->fatal("Argument is not a $base_class");

    $self->log_handler->add($output);

    return $self;
}

#-----------------------------------------------------------------------------

sub fatal {
    my ($self, $message) = @_;
    my $meth = $self->log_level eq 'debug' ? 'log_and_confess' : 'log_and_die';
    $self->log_handler->$meth(level => 'fatal', message => $message);
}


#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__

=head1 LOGGING METHODS

The following methods are available for writing to the logs at various
levels (listed in order of increasing priority).  Each method takes a
single message as an argument.

=over

=item debug

=item info

=item notice

=item warning

=item error

=item fatal

Note that C<fatal> causes the application to throw an exception.

=back

=cut
