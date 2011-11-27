package Pinto;

# ABSTRACT: Curate your own CPAN-like repository

use Moose;

use Class::Load;

use Pinto::Config;
use Pinto::Logger;
use Pinto::Locker;
use Pinto::Batch;
use Pinto::Repository;
use Pinto::Exceptions qw(throw_fatal);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

#------------------------------------------------------------------------------

has repos   => (
    is         => 'ro',
    isa        => 'Pinto::Repository',
    lazy_build => 1,
);


has locker  => (
    is         => 'ro',
    isa        => 'Pinto::Locker',
    init_arg   =>  undef,
    lazy_build => 1,
);


has _batch => (
    is         => 'ro',
    isa        => 'Pinto::Batch',
    writer     => '_set_batch',
    init_arg   => undef,
);


#------------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable );

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

sub _build_repos {
    my ($self) = @_;

    return Pinto::Repository->new( config => $self->config(),
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

sub new_batch {
    my ($self, %args) = @_;

    my $batch = Pinto::Batch->new( config => $self->config(),
                                   logger => $self->logger(),
                                   repos  => $self->repos(),
                                   %args );

   $self->_set_batch( $batch );

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
                                      repos  => $self->repos(),
                                      %args );

    $self->_batch->enqueue($action);

    return $self;
}

#------------------------------------------------------------------------------

sub run_actions {
    my ($self) = @_;

    my $batch = $self->_batch()
        or throw_fatal 'You must create a batch first';

    # Divert any warnings to our logger
    local $SIG{__WARN__} = sub { $self->whine(@_) };

    # Shit happens here!
    $self->locker->lock();
    my $r = $self->_batch->run();
    $self->locker->unlock();

    return $r;

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

See L<pinto-admin> to create and manage your Pinto repository.

See L<pinto-server> to allow remote access to your Pinto repository.

See L<pinto-remote> to interact with a remote Pinto repository.

See L<Pinto::Manual> for detailed information about the Pinto tools.

=head1 DESCRIPTION

L<Pinto> is a suite of tools for creating and managing a CPAN-style
repository of Perl archives.  Pinto is inspired by L<CPAN::Mini> and
L<CPAN::Mini::Inject>, but adds several novel features:

=over 4

=item * Pinto lets you build a repository with only your local archives.


=item * Pinto supports adding AND removing archives from the repository.


=item * Pinto can be integrated with your version control system.


=item * Pinto makes it easier to build several local repositories.


=item * Pinto can pull archives from multiple remote repositories.


=item * Pinto supports team development (i.e. concurrent users).


=item * Pinto has a robust command line interface.


=item * Pinto can be extended with new commands.

=back

=cut
