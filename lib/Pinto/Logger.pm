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
    # TODO: Default log_level to 1.  Maybe delegate this
    return $self->config()->get('log_level');
}

#-----------------------------------------------------------------------------
# Private functions

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
