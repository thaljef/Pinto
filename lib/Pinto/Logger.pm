package Pinto::Logger;

# ABSTRACT: A simple logger

use Moose;
use Moose::Util::TypeConstraints;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Moose attributes

has log_level => (
    is      => 'ro',
    builder => '__build_log_level',
    lazy    => 1,
);


#-----------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Configurable);

#-----------------------------------------------------------------------------
# Builders

sub __build_log_level {
    my ($self) = @_;
    return -2 if $self->config->quiet();
    return $self->config->verbose();
}

#-----------------------------------------------------------------------------
# Private functions

sub _logit {
    my ($message) = @_;
    print "$message\n";
}

#-----------------------------------------------------------------------------
# Public methods

sub debug {
    my ($self, $message, $opts) = @_;
    _logit($message, $opts) if $self->log_level() >= 1;
}

#-----------------------------------------------------------------------------

sub log {
    my ($self, $message, $opts) = @_;
    _logit($message, $opts) if $self->log_level() >= 0;
}

#-----------------------------------------------------------------------------

sub warn {
    my ($self, $message) = @_;
    CORE::warn "$message\n" if $self->log_level() >= -1;
}

#-----------------------------------------------------------------------------

sub fatal {
    my ($self, $message) = @_;
    die "$message\n";
}

#-----------------------------------------------------------------------------

1;

__END__
