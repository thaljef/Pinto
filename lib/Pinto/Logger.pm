package Pinto::Logger;

# ABSTRACT: A simple logger

use Moose;
use MooseX::Types::Moose qw(Int);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Moose attributes

has log_level => (
    is         => 'ro',
    isa        => Int,
    lazy_build => 1,
);


#-----------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Configurable);

#-----------------------------------------------------------------------------
# Builders

sub _build_log_level {
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

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
