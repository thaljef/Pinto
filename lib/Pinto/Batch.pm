package Pinto::Batch;

# ABSTRACT: Runs a series of actions

use Moose;

use DateTime;
use Path::Class;
use Exception::Class::TryCatch;

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

    $self->store->initialize() unless $self->noinit();

    while ( my $action = $self->dequeue() ) {
        $self->_run_one_action($action);
    }

    $self->debug('No changes were made') and return $self->_result()
      unless $self->_result->changes_made();

    $self->db->write_index();

    return $self->_result() if $self->nocommit();

    $self->_do_vcs_stuff() if $self->store->isa('Pinto::Store::VCS');

    return $self->_result();
}

#-----------------------------------------------------------------------------

sub _run_one_action {
    my ($self, $action) = @_;

    eval { $action->execute() and $self->_result->made_changes() };

    if ( catch my $e, ['Pinto::Exception'] ) {
        $self->_result->add_exception($e);
        $self->whine($e);
        return $self;
    }

    for my $msg ( $action->messages() ) {
        $self->append_message("\n\n") if length $self->message();
        $self->append_message($msg);
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub _do_vcs_stuff {
    my ($self) = @_;

    $self->store->mark_path_as_modified( $self->config->modules_dir() );
    $self->store->mark_path_as_modified( $self->config->db_dir() );

    $self->store->commit( message => $self->message() );

    if ( $self->has_tag() ) {
        my $now = DateTime->now();
        my $tag = $now->strftime( $self->tag() );
        $self->store->tag( tag => $tag );
    }

    return $self;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
