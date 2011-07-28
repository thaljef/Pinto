package Pinto::Logger;

# ABSTRACT: A simple logger

use MooseX::Singleton;
use Moose::Util::TypeConstraints;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Moose attributes

has log_level => (
    is      => 'ro',
    isa     => enum( [qw(0 1 2) ] ),
    default => 1,
);

#-----------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Configurable);

#-----------------------------------------------------------------------------
# Public attributes

sub _logit {
    my ($message, $opts) = @_;
    $opts ||= {};

    print $message;
    print "\n" unless $opts->{nolf};
}

#-----------------------------------------------------------------------------
# Public methods

sub debug {
    my ($self, $message, $opts) = @_;
    _logit($message, $opts) if $self->log_level() <= 0;
}

#-----------------------------------------------------------------------------

sub log {
    my ($self, $message, $opts) = @_;
    _logit($message, $opts) if $self->log_level() <= 1;
}

#-----------------------------------------------------------------------------

sub warn {
    my ($self, $message) = @_;
    CORE::warn $message if $self->log_level() <= 2;
}

#-----------------------------------------------------------------------------

sub fatal {
    my ($self, $message) = @_;
    die "$message\n";
}

#-----------------------------------------------------------------------------

1;

__END__
