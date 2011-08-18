package Pinto::Locker;

# ABSTRACT: Synchronize concurrent Pinto actions

use Moose;

use Carp;
use Path::Class;
use LockFile::Simple;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Moose attributes

has _lock => (
    is       => 'rw',
    isa      => 'LockFile::Lock',
    init_arg => undef,
);

#-----------------------------------------------------------------------------
# Moose roles

with qw ( Pinto::Role::Configurable
          Pinto::Role::Loggable );

#-----------------------------------------------------------------------------

sub lock {
    my ($self) = @_;

    my $local = $self->config->local();
    my $wfunc = sub { $self->logger->debug(@_) };
    my $efunc = sub { $self->logger->fatal(@_) };

    my $lockmgr = LockFile::Simple->make( -autoclean => 1,
                                          -efunc     => $efunc,
                                          -wfunc     => $wfunc,
                                          -stale     => 1,
                                          -nfs       => 1 );

    my $lock = $lockmgr->lock( $local . '/' )
        or croak 'Unable to lock the repository.  Please try later.';

    $self->logger->debug("Process $$ got the lock for $local");
    $self->_lock($lock);

    return $self;
}

#-----------------------------------------------------------------------------

sub unlock {
    my ($self) = @_;

    $self->_lock->release()
        or croak 'Unable to unlock the repository';

    return $self;
}

#-----------------------------------------------------------------------------
1;

__END__

