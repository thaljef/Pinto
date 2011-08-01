package Pinto::EventBatch;

# ABSTRACT: Runs a series of events

use Moose;
use Moose::Autobox;

use Pinto::IndexManager;

#-----------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has 'store' => (
    is       => 'ro',
    isa      => 'Pinto::Store',
    builder  => '__build_store',
    init_arg => undef,
    lazy     => 1,
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
# Builders

sub __build_store {
   my ($self) = @_;

   my $store_class = $self->config()->get('store_class') || 'Pinto::Store';
   Class::Load::load_class($store_class);

   return $store_class->new( config => $self->config(),
                             logger => $self->logger() );
}

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

    if ($self->config()->get('force')
        or not $self->store()->is_initialized()) {
        $self->store()->initialize();
    }

    my $changes_were_made = 0;
    for my $event ( $self->events()->flatten() ) {
        $changes_were_made += $event->execute();
    }

    if ($self->config()->get('nocommit')) {
        $self->logger->log('Not committing due to --nocommit flag');
        return $self;
    }

    if ($changes_were_made) {
        my @event_messages = map {$_->message()} $self->events()->flatten();
        my $batch_message  = join "\n\n", grep {length} @event_messages;
        $self->store()->finalize(message => $batch_message);
        return $self;
    }

    $self->logger()->debug('No changes were made');

    return $self;
}

#-----------------------------------------------------------------------------

1;

__END__
