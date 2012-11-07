# ABSTRACT: Report statistics about the repository

package Pinto::Action::Statistics;

use Moose;

use Pinto::Types qw(StackName StackDefault StackObject);
use Pinto::Statistics;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # FIXME!
    my $stack = $self->repo->get_stack($self->stack);

    my $stats = Pinto::Statistics->new(db    => $self->repo->db,
                                       stack => $stack->name);

    $self->say($stats->to_formatted_string);

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
