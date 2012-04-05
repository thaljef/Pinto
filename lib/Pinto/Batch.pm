package Pinto::Batch;

# ABSTRACT: Runs a series of actions

use Moose;

use DateTime;
use Path::Class;
use Try::Tiny;

use Pinto::Locker;
use Pinto::Result;

use Pinto::Types 0.017 qw(Dir);
use MooseX::Types::Moose qw(Str Bool);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Loggable
         Pinto::Interface::Configurable );

#------------------------------------------------------------------------------
# Attributes

has repos    => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1
);


has messages => (
    isa        => 'ArrayRef[Str]',
    traits     => [ 'Array' ],
    handles    => {
        add_message => 'push',
        messages    => 'elements',
    },
    default    => sub { [] },
    init_arg   => undef,
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


has locker  => (
    is         => 'ro',
    isa        => 'Pinto::Locker',
    init_arg   =>  undef,
    lazy_build => 1,
);


has actions => (
    is       => 'ro',
    isa      => 'ArrayRef[Pinto::Action]',
    traits   => [ 'Array' ],
    handles  => {enqueue => 'push', dequeue => 'shift'},
    init_arg => undef,
    default  => sub { [] },
);

#-----------------------------------------------------------------------------
# Private attributes

has _result => (
    is       => 'ro',
    isa      => 'Pinto::Result',
    default  => sub { Pinto::Result->new() },
    init_arg => undef,
);

#-----------------------------------------------------------------------------
# Builders

sub _build_locker {
    my ($self) = @_;

    return Pinto::Locker->new( config => $self->config(),
                               logger => $self->logger() );
}

#------------------------------------------------------------------------------
# Public methods

=method run()

Runs all the actions in this Batch.  Returns a L<Pinto::Result>.

=cut

sub run {
    my ($self) = @_;

    # Divert any warnings to our logger
    local $SIG{__WARN__} = sub { $self->whine(@_) };

    $self->locker->lock();
    $self->repos->initialize() unless $self->noinit();

    while ( my $action = $self->dequeue() ) {
        $self->_run_action($action);
    }

    if (not $self->_result->changes_made) {
        $self->note('No changes were made');
        goto BATCH_DONE;
    }

    $self->repos->write_index();

    $self->debug( $self->message_string() );

    if (not $self->nocommit) {
        my $msg = $self->message_string();
        my $tag = $self->tag();
        $self->repos->commit(message => $msg);
        $self->repos->tag(tag => $tag, message => $msg) if $tag;
    }

  BATCH_DONE:
    $self->locker->unlock();
    return $self->_result();
}

#-----------------------------------------------------------------------------

sub message_string {
    my ($self) = @_;

    return join "\n\n", grep { length } $self->messages(), "\n";
}

#-----------------------------------------------------------------------------

sub _run_action {
    my ($self, $action) = @_;

    try   { $action->execute() && $self->_result->made_changes() }
    catch { $self->_handle_action_error( $_ ) };

    $self->add_message( $action->messages() );

    return $self;
}

#-----------------------------------------------------------------------------

sub _handle_action_error {
    my ($self, $error) = @_;

    if ( blessed($error) && $error->isa('Pinto::Exception') ) {
        $self->_result->add_exception($error);
        $self->whine($error);
        return $self;
    }

    $self->fatal($error);

    return $self;  # Should never get here
}


#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
