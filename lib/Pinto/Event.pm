package Pinto::Event;

# ABSTRACT: Base class for events

use Moose;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

=attr message()

Returns the message associated with this transaction.

=cut

has message => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_message',
    default  => 'NO MESSAGE GIVEN',
    init_arg => undef,
);

with qw(Pinto::Role::Configurable Pinto::Role::Loggable);

#------------------------------------------------------------------------------

=method prepare()

The C<prepare> method is called before each transaction is executed.
This gives the transaction an opportunity to validate its self.  If
anything smells fishy, throw an exception.

=cut

sub prepare { return 1 }

=method execute()

Executes the transaction.  Throws an exception if anything goes wrong.

=cut

sub execute { return 1 }

=method rollback()

Restores the universe to the state before the transaction.  This should
be called if the C<execute()> method throws an exception.

=cut

sub rollback { return 1 }

#------------------------------------------------------------------------------

1;

__END__
