# ABSTRACT: Report statistics about the repository

package Pinto::Action::Statistics;

use Moose;
use MooseX::Types::Moose qw(Undef);

use Pinto::Types qw(StackName);
use Pinto::Statistics;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | Undef,
    default   => undef,
    coerce    => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # FIXME!
    my $stack = $self->repos->get_stack(name => $self->stack);

    my $stats = Pinto::Statistics->new(db    => $self->repos->db,
                                       stack => $stack->name);

    $self->say($stats->to_formatted_string);

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
