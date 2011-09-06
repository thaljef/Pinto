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


has noinit   => (
    is       => 'ro',
    isa      => Bool,
    builder  => '_build_noinit',
    lazy     => 1,
);


has nolock => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);


has tag => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_tag',
);

#-----------------------------------------------------------------------------
# Private attributes

has _actions => (
    is       => 'ro',
    isa      => 'ArrayRef[Pinto::Action]',
    traits   => [ 'Array' ],
    default  => sub { [] },
    handles  => {enqueue => 'push', dequeue => 'shift'},
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

sub _build_noinit {
    my ($self) = @_;

    return $self->config->noinit();
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
        $self->_locker->unlock() unless $self->nolock();
    };

    return $self->_result();
}

#-----------------------------------------------------------------------------

sub _run_actions {
    my ($self) = @_;

    $self->store->initialize() unless $self->noinit();

    while ( my $action = $self->dequeue() ) {
        $self->_run_one_action($action);
    }

    $self->logger->info('No changes were made') and return $self
      unless $self->_result->changes_made();

    $self->idxmgr->write_indexes();

    return $self if $self->nocommit();

    if ( $self->store->isa('Pinto::Store::VCS') ) {

        my $modules_dir = $self->config->modules_dir();
        $self->store->mark_path_as_modified($modules_dir);

        $self->store->commit( message => $self->message() );

        # TODO: Expand date placeholders in tag
        $self->store->tag( tag => $self->tag() ) if $self->has_tag();
    }

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
