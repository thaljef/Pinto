package Pinto::ActionBatch;

# ABSTRACT: Runs a series of actions

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

has actions => (
    is       => 'ro',
    isa      => 'ArrayRef[Pinto::Action]',
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

=method add(action => $some_action)

Pushes C<$some_action> onto the stack of L<Pinto::Action>s that will be
run.

=cut

sub add {
    my ($self, %args) = @_;

    my $action = $args{action};
    $action = [$action] if ref $action ne 'ARRAY';

    $self->actions()->push( $action->flatten() );

    return $self;
}

#-----------------------------------------------------------------------------
# TODO: Trap exceptions here...

=method run()

Runs all the actions in this Batch.  First, the C<prepare> method will
be called on each Action, and then the C<execute> method will be called
on each Action.

=cut

sub run {
    my ($self) = @_;

    if ($self->config()->get('force')
        or not $self->store()->is_initialized()) {
        $self->store()->initialize();
    }

    my $changes_were_made = 0;
    for my $action ( $self->actions()->flatten() ) {
        $changes_were_made += $action->execute();
    }

    if ($self->config()->get('nocommit')) {
        $self->logger->log('Not committing due to --nocommit flag');
        return $self;
    }

    if ($changes_were_made) {
        my @action_messages = map {$_->message()} $self->actions()->flatten();
        my $batch_message  = join "\n\n", grep {length} @action_messages;
        $self->store()->finalize(message => $batch_message);
        return $self;
    }

    $self->logger()->debug('No changes were made');

    return $self;
}

#-----------------------------------------------------------------------------

1;

__END__
