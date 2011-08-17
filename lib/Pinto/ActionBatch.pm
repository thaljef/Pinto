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
    required => 1
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

with qw( Pinto::Role::Loggable
         Pinto::Role::Configurable );

#-----------------------------------------------------------------------------

=method enqueue($some_action)

Adds C<$some_action> to the end of the queue of L<Pinto::Action>s that will be
run.  Returns a reference to this C<ActionBatch>.

=cut

sub enqueue {
    my ($self, @actions) = @_;

    $self->actions()->push( @actions );

    return $self;
}

#-----------------------------------------------------------------------------
# TODO: Trap exceptions here...

=method run()

Runs all the actions in this Batch.  Returns a reference to this C<ActionBatch>.

=cut

sub run {
    my ($self) = @_;

    $self->store->initialize()
        unless $self->store->is_initialized()
           and $self->config->noinit();


    my @messages;
    my $changes_were_made;
    while ( my $action = $self->actions->shift() ) {
        # TODO: Trap exceptions here?
        $changes_were_made += $action->execute();
        push @messages, $action->messages->flatten();
    }


    $self->logger->info('No changes were made') and return $self
      unless $changes_were_made;


    $self->idxmgr->write_indexes();
    # Always put the modules directory on the commit list!
    my $modules_dir = $self->config->local->subdir('modules');
    $self->store->modified_paths->push( $modules_dir );

    return $self if $self->config->nocommit();

    my $batch_message  = join "\n\n", @messages;
    $self->logger->debug($batch_message);
    $self->store->finalize(message => $batch_message);

    return $self;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
