package Pinto::ActionBatch;

# ABSTRACT: Runs a series of actions

use Moose;

use Try::Tiny;
use Path::Class;

use Pinto::Locker;
use Pinto::BatchResult;

use Pinto::Types 0.017 qw(Dir);
use MooseX::Types::Moose qw(Str Bool);

#-----------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has config    => (
    is        => 'ro',
    isa       => 'Pinto::Config',
    required => 1,
);

has store    => (
    is       => 'ro',
    isa      => 'Pinto::Store',
    required => 1
);

has idxmgr => (
    is       => 'ro',
    isa      => 'Pinto::IndexManager',
    required => 1,
);

# TODO: make private?
has actions => (
    is       => 'ro',
    isa      => 'ArrayRef[Pinto::Action]',
    traits   => [ 'Array' ],
    default  => sub { [] },
    handles  => {enqueue => 'push', dequeue => 'shift'},
);

has message => (
    is       => 'ro',
    isa      => Str,
    traits   => [ 'String' ],
    handles  => {append_message => 'append'},
    default  => '',
);

has nocommit => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

has nolock => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has _locker  => (
    is       => 'ro',
    isa      => 'Pinto::Locker',
    builder  => '_build__locker',
    init_arg =>  undef,
    lazy     => 1,
);

has _result => (
    is       => 'ro',
    isa      => 'Pinto::BatchResult',
    builder  => '_build__result',
    init_arg => undef,
);

#-----------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Role::Loggable
         Pinto::Role::Configurable );

#-----------------------------------------------------------------------------
# Builders

sub _build__locker {
    my ($self) = @_;

    return Pinto::Locker->new( repos  => $self->config->repos(),
                               logger => $self->logger() );
}

#-----------------------------------------------------------------------------
# TODO: I don't like having the result as an attribute.  I would prefer
# to keep it transient, so that it doesn't survive beyond each run().

sub _build__result {
    my ($self) = @_;

    return Pinto::BatchResult->new();
}

#-----------------------------------------------------------------------------
# Public methods

=method run()

Runs all the actions in this Batch.  Returns a L<BatchResult>.

=cut

sub run {
    my ($self) = @_;

    try {
        $self->_locker->lock() unless $self->nolock();
        $self->_run_actions();
    }
    catch {
        $self->logger->whine($_);
        $self->_result->add_exception($_);
    }
    finally {
        # TODO: do we first need to check if it actually is locked?
        $self->_locker->unlock() unless $self->nolock();
    };

    return $self->_result();
}

#-----------------------------------------------------------------------------

sub _run_actions {
    my ($self) = @_;

    # TODO: I'm not sure we is_initialized() is really necessary.  But
    # we probably do need to make sure that the repos actually is a
    # repository.

    $self->store->initialize()
        unless $self->store->is_initialized()
           and $self->config->noinit();

    while ( my $action = $self->dequeue() ) {
        $self->_run_one_action($action);
    }

    $self->logger->info('No changes were made') and return $self
      unless $self->_result->changes_made();

    $self->idxmgr->write_indexes();

    return $self if $self->nocommit();

    if ( $self->store->isa('Pinto::Store::VCS') ) {
        # TODO: make the module dir an attribute of something.
        # Maybe on Config, or Pinto itself?
        my $modules_dir = $self->config->repos->subdir('modules');
        $self->store->mark_path_as_modified($modules_dir);
    }

    $self->store->finalize( message => $self->message() );

    return $self;
}

#-----------------------------------------------------------------------------

sub _run_one_action {
    my ($self, $action) = @_;

    try   {
        my $changes = $action->execute();
        $self->_result->made_changes() if $changes;
    }
    catch {
        # Collect unhandled exceptions
        $self->logger->whine($_);
        $self->_result->add_exception($_);
    }
    finally {
        # Collect handled exceptions
        $self->_result->add_exception($_) for $action->exceptions();
    };

    for my $msg ( $action->messages() ) {
        $self->append_message("\n\n") if length $self->message();
        $self->append_message($msg);
    }

    return $self;
}


#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
