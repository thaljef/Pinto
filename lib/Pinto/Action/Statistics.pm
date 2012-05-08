# ABSTRACT: Report statistics about the repository

package Pinto::Action::Statistics;

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Statistics;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Reporter );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => Str,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # FIXME!
    my $stack = $self->repos->get_stack( $self->stack );
    my $stats = Pinto::Statistics->new( db    => $self->repos->db,
                                        stack => $stack->name );

    print { $self->out } $stats->to_formatted_string();

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
