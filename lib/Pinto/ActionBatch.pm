package Pinto::ActionBatch;

# ABSTRACT: Runs a series of actions

use Moose;

use Carp;
use Try::Tiny;
use Path::Class;

use Pinto::Locker;

use Pinto::Types qw(Dir);
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

has _locker  => (
    is       => 'ro',
    isa      => 'Pinto::Locker',
    builder  => '_build__locker',
    init_arg =>  undef,
    lazy     => 1,
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
# Public methods

=method run()

Runs all the actions in this Batch.  Returns a reference to this C<ActionBatch>.

=cut

sub run {
    my ($self) = @_;

    $self->_locker->lock();
    $self->_run_actions();
    $self->_locker->unlock();

    return $self;
}

#-----------------------------------------------------------------------------

sub _run_actions {
    my ($self) = @_;

    $self->store->initialize()
        unless $self->store->is_initialized()
           and $self->config->noinit();


    my $changes_were_made;
    while ( my $action = $self->dequeue() ) {
        $changes_were_made += $self->_run_one_action($action);
    }

    $self->logger->debug('No changes were made') and return $self
      unless $changes_were_made;

    $self->idxmgr->write_indexes();

    return $self if $self->nocommit();

    if ( $self->store->isa('Pinto::Store::VCS') ) {
        my $modules_dir = $self->config->repos->subdir('modules');
        $self->store->mark_path_as_modified($modules_dir)
    }

    $self->store->finalize( message => $self->message() );

    return $self;
}

#-----------------------------------------------------------------------------

sub _run_one_action {
    my ($self, $action) = @_;

    my $changes_were_made = 0;

    try   { $changes_were_made += $action->execute() }
    catch { $self->logger->whine($_) };

    for my $msg ( $action->messages() ) {
        $self->message() and $self->append_message("\n\n");
        $self->append_message($msg);
    }

    return $changes_were_made;
}


#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
