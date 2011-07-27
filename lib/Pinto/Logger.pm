package Pinto::Logger;

# ABSTRACT: A simple logger

use Moose;
use Moose::Util::TypeConstraints;
use Readonly;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Some constants

Readonly my @LOG_LEVEL_NAMES => qw(debug info warn fatal);
Readonly my %LOG_LEVEL_NUMBERS => map { $LOG_LEVEL_NAMES[$_] => $_ } (0..3);

#-----------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Configurable);

#-----------------------------------------------------------------------------
# Public attributes

sub log_level {
    my ($self) = @_;
    return $self->config()->get('log_level') || 'info';
}

#-----------------------------------------------------------------------------
# Private Methods

sub _log_level {
    my ($self) = @_;
    return $LOG_LEVEL_NUMBERS{ $self->log_level() };
}

#-----------------------------------------------------------------------------

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
    _logit($message, $opts) if $self->_log_level() <= 0;
}

#-----------------------------------------------------------------------------

sub info {
    my ($self, $message, $opts) = @_;
    _logit($message, $opts) if $self->_log_level() <= 1;
}

#-----------------------------------------------------------------------------

sub warn {
    my ($self, $message) = @_;
    CORE::warn if $self->_log_level() <= 2;
}

#-----------------------------------------------------------------------------

sub fatal {
    my ($self, $message) = @_;
    die "$message\n";
}

#-----------------------------------------------------------------------------

1;

__END__
