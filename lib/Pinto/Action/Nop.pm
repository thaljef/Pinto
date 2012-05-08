# ABSTRACT: A no-op action

package Pinto::Action::Nop;

use Moose;
use MooseX::Types::Moose qw(Int);

use namespace::autoclean;

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

    if (my $sleep = $self->sleep) {
        $self->debug("Process $$ sleeping for $sleep seconds");
        sleep $self->sleep;
    }

    return $self->result->new;
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
