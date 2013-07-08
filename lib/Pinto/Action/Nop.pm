# ABSTRACT: A no-op action

package Pinto::Action::Nop;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Int);
use MooseX::MarkAsMethods ( autoclean => 1 );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has sleep => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    if ( my $sleep = $self->sleep ) {
        $self->notice("Process $$ sleeping for $sleep seconds");
        sleep $self->sleep;
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

=pod

=head1 DESCRIPTION

This action does nothing.  It can be used to get Pinto to initialize
the store and load the indexes without performing any real operations
on them.

=cut

1;

__END__
