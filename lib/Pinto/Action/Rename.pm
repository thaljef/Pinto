# ABSTRACT: Change the name of a stack

package Pinto::Action::Rename;

use Moose;

use Pinto::Types qw(StackName StackObject);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has from_stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->rename_stack( from => $self->from_stack,
                                           to   => $self->to_stack );

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
