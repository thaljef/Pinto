package Pinto::Transaction;

# ABSTRACT: Groups a series of events

use Moose;
use Moose::Autobox;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Moose attributes

has store => (
    is       => 'ro',
    isa      => 'Pinto::Store',
    required => 1,
);

has events => (
    is       => 'ro',
    isa      => 'ArrayRef[Pinto::Event]',
    default  => sub { [] },
);

#-----------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Loggable Pinto::Role::Configurable);

#-----------------------------------------------------------------------------

sub add {
    $DB::single = 1;
    my ($self, %args) = @_;

    my $event = $args{event};
    $event = [$event] if ref $event ne 'ARRAY';

    $self->events()->push( @{ $event } );

    return $self;
}

#-----------------------------------------------------------------------------

sub run {
    my ($self) = @_;

    $self->store()->initialize();

    $DB::single = 1;
    $_->prepare() for @{ $self->events() };
    $_->execute() for @{ $self->events() };

    my $message = join "\n\n", map {$_->message()} $self->events()->flatten();
    $self->store()->finalize(message => $message);

    return $self;
}

#-----------------------------------------------------------------------------

1;

__END__
