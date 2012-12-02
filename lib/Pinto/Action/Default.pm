# ABSTRACT: Set the default stack

package Pinto::Action::Default;

use Moose;

use Pinto::Types qw(StackName StackObject);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    default  => undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack    = $self->repo->get_stack($self->stack);
    my $did_mark = $stack->mark_as_default;

    $self->result->changed if $did_mark;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
