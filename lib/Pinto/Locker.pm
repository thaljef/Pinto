# ABSTRACT: Manage locks to synchronize concurrent operations

package Pinto::Locker;

use Moose;

use Path::Class;
use File::NFSLock;

use Pinto::Types qw(File);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has timeout => (
    is      => 'ro',
    isa     => 'Int',
    default => 50
);


has _lock => (
    is         => 'rw',
    isa        => 'File::NFSLock',
    predicate  => 'is_locked',
    init_arg   => undef,
);

#-----------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#-----------------------------------------------------------------------------

=method lock

Attempts to get a lock on a Pinto repository.  If the repository is already
locked, we will attempt to contact the current lock holder and make sure they
are really alive.  If not, then we will steal the lock.  If they are, then
we patiently wait until we timeout, which is about 60 seconds.

=cut

sub lock_exclusive {
    my ($self) = @_;

    my $root_dir  = $self->root_dir;
    throw "$root_dir is already locked" if $self->is_locked;

    my $lock_file = $root_dir->file('.lock')->stringify;
    my $lock = File::NFSLock->new($lock_file, 'EX', $self->timeout)
        or throw 'Unable to lock the repository -- please try later';

    $self->debug("Process $$ got exclusive lock on $root_dir");
    $self->_lock($lock);

    return $self;
}

#-----------------------------------------------------------------------------

sub lock_shared {
    my ($self) = @_;

    my $root_dir  = $self->root_dir;
    throw "$root_dir is already locked" if $self->is_locked;

    my $lock_file = $root_dir->file('.lock')->stringify;
    my $lock = File::NFSLock->new($lock_file, 'SH', $self->timeout)
        or throw 'Unable to lock the repository -- please try later';

    $self->debug("Process $$ got shared lock on $root_dir");
    $self->_lock($lock);

    return $self;
}

#-----------------------------------------------------------------------------

=method unlock

Releases the lock on the Pinto repository so that other processes can
get to work.

=cut

sub unlock {
    my ($self) = @_;

    return $self if not $self->is_locked;

    $self->_lock->unlock or throw 'Unable to unlock repository';

    my $root_dir = $self->config->root_dir;
    $self->debug("Process $$ released the lock on $root_dir");

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

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
