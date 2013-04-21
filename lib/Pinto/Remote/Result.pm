# ABSTRACT: The result from running a remote Action

package Pinto::Remote::Result;

use Moose;

use MooseX::Types::Moose qw(Bool);

#-----------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has was_successful => (
    is         => 'ro',
    isa        => Bool,
    default    => 0,
);

#-----------------------------------------------------------------------------

=method exit_status()

Returns 0 if this result was successful.  Otherwise, returns 1.

=cut

sub exit_status {
    my ($self) = @_;
    return $self->was_successful ? 0 : 1;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
