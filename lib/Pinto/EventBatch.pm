package Pinto::EventBatch;

# ABSTRACT: Runs a series of events

use Moose;
use Moose::Autobox;

use Pinto::IndexManager;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Moose attributes

has store => (
    is       => 'ro',
    isa      => 'Pinto::Store',
    required => 1,
);

has events => (
    is       => 'ro',
    isa      => 'ArrayRef[Pinto::Event]',
    default  => sub { [] },
);

#-----------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Loggable Pinto::Role::Configurable);

#-----------------------------------------------------------------------------

=method add(event => $some_event)

Pushes C<$some_event> onto the stack of L<Pinto::Event>s that will be
run.

=cut

sub add {
    my ($self, %args) = @_;

    my $event = $args{event};
    $event = [$event] if ref $event ne 'ARRAY';

    $self->events()->push( $event->flatten() );

    return $self;
}

#-----------------------------------------------------------------------------
# TODO: Trap exceptions here...

=method run()

Runs all the events in this Batch.  First, the C<prepare> method will
be called on each Event, and then the C<execute> method will be called
on each Event.

=cut

sub run {
    my ($self) = @_;

    $self->store()->initialize();

    for my $event ( $self->events()->flatten() ) {
      $event->prepare();
    }

    my $changes_were_made = 0;
    for my $event ( $self->events()->flatten() ) {
      $changes_were_made += $event->execute();
    }

    if ($changes_were_made) {
        my $idx_mgr = Pinto::IndexManager->instance();
        $idx_mgr->commit();

        my @event_messages = map {$_->message()} $self->events()->flatten();
        my $batch_message  = join "\n\n", grep {length} @event_messages;

        $self->logger()->debug("Commit message is:\n\n$batch_message");
        $self->store()->finalize(message => $batch_message);
    }
    else {
        $self->logger()->debug('No changes were made');
    }

    return $self;
}

#-----------------------------------------------------------------------------

1;

__END__
