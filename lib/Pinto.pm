package Pinto;

# ABSTRACT: Perl distribution repository manager

use Moose;

use Class::Load;

use Pinto::Config;
use Pinto::Logger;
use Pinto::Locker;
use Pinto::Database;
use Pinto::ActionBatch;

use Pinto::Exceptions qw(throw_fatal);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has _action_batch => (
    is         => 'ro',
    isa        => 'Pinto::ActionBatch',
    writer     => '_set_action_batch',
    init_arg   => undef,
);

#------------------------------------------------------------------------------

has db => (
    is          => 'ro',
    isa         => 'Pinto::Database',
    init_arg    => undef,
    lazy_build  => 1,
);

#------------------------------------------------------------------------------

has store => (
    is         => 'ro',
    isa        => 'Pinto::Store',
    init_arg   => undef,
    lazy_build => 1,
);

#------------------------------------------------------------------------------

has locker  => (
    is         => 'ro',
    isa        => 'Pinto::Locker',
    init_arg   =>  undef,
    lazy_build => 1,
);

#------------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------
# Construction

sub BUILDARGS {
    my ($class, %args) = @_;

    $args{logger} ||= Pinto::Logger->new( %args );
    $args{config} ||= Pinto::Config->new( %args );

    return \%args;
}


#------------------------------------------------------------------------------
# Builders

sub _build_db {
    my ($self) = @_;

    return Pinto::Database->new( config => $self->config(),
                                 logger => $self->logger() );
}

#------------------------------------------------------------------------------

sub _build_store {
    my ($self) = @_;

    my $store_class = $self->config->store();

    eval { Class::Load::load_class( $store_class ); 1 }
        or throw_fatal "Unable to load store class $store_class: $@";

    return $store_class->new( config => $self->config(),
                              logger => $self->logger() );
}

#------------------------------------------------------------------------------

sub _build_locker {
    my ($self) = @_;

    return Pinto::Locker->new( config => $self->config(),
                               logger => $self->logger() );
}

#------------------------------------------------------------------------------
# Public methods

sub new_action_batch {
    my ($self, %args) = @_;

    my $batch = Pinto::ActionBatch->new( config => $self->config(),
                                         logger => $self->logger(),
                                         store  => $self->store(),
                                         db     => $self->db(),
                                         %args );

   $self->_set_action_batch( $batch );

   return $self;
}

#------------------------------------------------------------------------------

sub add_action {
    my ($self, $action_name, %args) = @_;

    my $action_class = "Pinto::Action::$action_name";

    eval { Class::Load::load_class($action_class); 1 }
        or throw_fatal "Unable to load action class $action_class: $@";

    my $action =  $action_class->new( config => $self->config(),
                                      logger => $self->logger(),
                                      store  => $self->store(),
                                      db     => $self->db(),
                                      %args );

    $self->_action_batch->enqueue($action);

    return $self;
}

#------------------------------------------------------------------------------

sub run_actions {
    my ($self) = @_;

    my $action_batch = $self->_action_batch()
        or throw_fatal 'You must create an action batch first';

    $self->locker->lock();

    my $r = $self->_action_batch->run();

    $self->locker->unlock();

    return $r;

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords PASSed

=head1 SYNOPSIS

There is nothing for you to see here. Instead, please look at one or
more of the following:

See L<Pinto::Manual> for broad information about the Pinto tools.

See L<pinto-admin> to create and manage your Pinto repository.

See L<pinto-server> to allow remote access to your Pinto repository.

See L<pinto-remote> to interact with a remote Pinto repository.

=cut
