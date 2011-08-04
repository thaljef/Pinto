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


has idxmgr => (
    is       => 'ro',
    isa      => 'Pinto::IndexManager',
    required => 1,
);

#-----------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Loggable Pinto::Role::Configurable);

#-----------------------------------------------------------------------------
# Builders

sub __build_store {
   my ($self) = @_;

   my $store_class = $self->config->store_class();
   Class::Load::load_class($store_class);

   return $store_class->new( config => $self->config(),
                             logger => $self->logger() );
}

#-----------------------------------------------------------------------------

=method enqueue($some_action)

Adds C<$some_action> to the end of the queue of L<Pinto::Action>s that will be
run.

=cut

sub enqueue {
    my ($self, @actions) = @_;

    $self->actions()->push( @actions );

    return $self;
}

#-----------------------------------------------------------------------------
# TODO: Trap exceptions here...

=method run()

Runs all the actions in this Batch.

=cut

sub run {
    my ($self) = @_;

    # TODO: don't initialize if we don't have to!
    $self->store()->initialize();

    my $changes_were_made;
    while( my $action = $self->actions()->shift() ) {

      # HACK: To avoid running cleanup if we don't
      # have to.  But we still need to run it when
      # explicitly asked to run a 'Clean' action.
      next if $action->isa('Pinto::Action::Clean')
        && defined $changes_were_made
          && $changes_were_made == 0;

        $changes_were_made += $action->execute();

    }

    if ($changes_were_made) {

        $self->idxmgr()->write_indexes();

        if ( $self->config->nocommit() ) {
            $self->logger->log('Not committing due to nocommit flag');
            return $self;
        }

        my @action_messages = map {$_->message()} $self->actions()->flatten();
        my $batch_message  = join "\n\n", grep {length} @action_messages;
        $self->store()->finalize(message => $batch_message);
        return $self;
    }

    return $self;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta()->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
