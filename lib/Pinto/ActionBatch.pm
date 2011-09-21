package Pinto::ActionBatch;

# ABSTRACT: Runs a series of actions

use Moose;

use Try::Tiny;
use Path::Class;

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


has db => (
    is       => 'ro',
    isa      => 'Pinto::Database',
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
    default  => sub { $_[0]->config->noinit() },
    lazy     => 1,
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
    init_arg => undef,
);


has _result => (
    is       => 'ro',
    isa      => 'Pinto::BatchResult',
    default  => sub { Pinto::BatchResult->new() },
    init_arg => undef,
);

#-----------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Role::Loggable
         Pinto::Role::Configurable );

#-----------------------------------------------------------------------------
# Public methods

=method run()

Runs all the actions in this Batch.  Returns a L<BatchResult>.

=cut

sub run {
    my ($self) = @_;

    try {
        $self->_run_actions();
    }
    catch {
        $self->logger->whine($_);
        $self->_result->add_exception($_);
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

    my $index_file = $self->config->modules_dir->file('02packages.details.txt.gz');
    $self->db->write_index($index_file);

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
