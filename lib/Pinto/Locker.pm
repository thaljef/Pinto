package Pinto::Locker;

# ABSTRACT: Synchronize concurrent Pinto actions

use Moose;

use Carp;
use Path::Class;
use LockFile::Simple;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Moose attributes

has _lock => (
    is         => 'rw',
    isa        => 'LockFile::Lock',
    init_arg   => undef,
);

has _lockmgr => (
    is         => 'ro',
    isa        => 'LockFile::Simple',
    init_arg   => undef,
    lazy_build => 1,

);

#-----------------------------------------------------------------------------
# Moose roles

with qw ( Pinto::Role::Configurable
          Pinto::Role::Loggable );

#-----------------------------------------------------------------------------
# Builders

sub _build__lockmgr {
    my ($self) = @_;

    my $wfunc = sub { $self->logger->debug(@_) };
    my $efunc = sub { $self->logger->fatal(@_) };

    return LockFile::Simple->make( -autoclean => 1,
                                   -efunc     => $efunc,
                                   -wfunc     => $wfunc,
                                   -stale     => 1,
                                   -nfs       => 1 );
}

#-----------------------------------------------------------------------------
# Methods

=method lock()

Attempts to get a lock on the Pinto repository.  If the repository is already
locked, we will attempt to contact the current lock holder and make sure they
are really alive.  If not, then we will steal the lock.  If they are, then
we patiently wait until we timeout, which is about 60 seconds.

=cut

sub lock {                                             ## no critic (Homonym)
    my ($self) = @_;

    my $repos = $self->config->repos();

    my $lock = $self->_lockmgr->lock( $repos . '/' )
        or croak 'Unable to lock the repository.  Please try later.';

    $self->logger->debug("Process $$ got the lock for $repos");
    $self->_lock($lock);

    return $self;
}

#-----------------------------------------------------------------------------

=method unlock()

Releases the lock on the Pinto repository so that other processes can
get to work.

=cut

sub unlock {
    my ($self) = @_;

    my $repos = $self->config->repos();
    $self->logger->debug("Releasing lock on $repos");

    $self->_lock->release() or croak "Unable to unlock repository";

    return $self;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

=for stopwords NFS

In many situations, a Pinto repository is a shared resource.  At any
given moment, multiple processes may be trying to add distributions,
remove packages, or pull files from a mirror.  To keep things working
properly, we can only let one process fiddle with the repository at a
time.  This module manages a lock file for that purpose.

Supposedly, this does work on NFS.  But it cannot steal the lock from
a dead process if that process was not running on the same host.
