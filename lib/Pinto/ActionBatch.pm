package Pinto::ActionBatch;

# ABSTRACT: Runs a series of actions

use Moose;
use Moose::Autobox;

use Carp;
use Try::Tiny;
use Path::Class;
use LockFile::Simple;

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

has lock => (
    is       => 'rw',
    isa      => 'LockFile::Lock',
    init_arg => undef,
);

has message => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_message',
    default  => '',
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

=method run()

Runs all the actions in this Batch.  Returns a reference to this C<ActionBatch>.

=cut

sub run {
    my ($self) = @_;

    $self->_obtain_lock();
    $self->_run_actions();
    $self->_release_lock();

    return $self;
}

#-----------------------------------------------------------------------------

sub _run_actions {
    my ($self) = @_;

    $self->store->initialize()
        unless $self->store->is_initialized()
           and $self->config->noinit();


    my $changes_were_made;
    while ( my $action = $self->actions->shift() ) {
        $changes_were_made += $self->_run_one_action($action);
    }

    $self->logger->info('No changes were made') and return $self
      unless $changes_were_made;

    $self->idxmgr->write_indexes();

    return $self if $self->config->nocommit();

    # Always put the modules directory on the commit list!
    my $modules_dir = $self->config->local->subdir('modules');
    $self->store->modified_paths->push( $modules_dir );

    my $batch_message = $self->message();
    $self->logger->debug($batch_message);
    $self->store->finalize(message => $batch_message);

    return $self;
}

#-----------------------------------------------------------------------------

sub _run_one_action {
    my ($self, $action) = @_;

    my $changes_were_made = 0;

    try {
        $changes_were_made += $action->execute();
        my @messages, $action->messages->flatten();
        $self->_append_messages(@messages);
    }
    catch {
        $self->logger->whine($_);
    };

    return $changes_were_made;
}


#-----------------------------------------------------------------------------

sub _append_messages {
    my ($self, @messages) = @_;

    my $current_message = $self->message();
    $current_message .= "\n\n" if $current_message;
    my $new_message = join "\n\n", @messages;
    $self->_set_message($new_message);

    return $self;
}

#-----------------------------------------------------------------------------

sub _obtain_lock {
    my ($self) = @_;

    my $wfunc = sub { $self->logger->debug(@_) };
    my $efunc = sub { $self->logger->fatal(@_) };

    my $lockmgr = LockFile::Simple->make( -autoclean => 1,
                                          -efunc     => $efunc,
                                          -wfunc     => $wfunc,
                                          -stale     => 1,
                                          -nfs       => 1 );

    $DB::single = 1;
    my $lock = $lockmgr->lock( $self->config->local() . '/' )
        or croak 'Unable to lock the repository.  Please try later.';

    $self->lock($lock);

    return $self;
}

#-----------------------------------------------------------------------------

sub _release_lock {
    my ($self) = @_;

    $self->lock->release()
        or croak 'Unable to release the repository lock';

    return $self;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
