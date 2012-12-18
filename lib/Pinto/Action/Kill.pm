# ABSTRACT: Permanently delete a stack

package Pinto::Action::Kill;

use Moose;
use MooseX::Types::Moose qw(Bool);

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
    required => 1,
);


has force => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);

    $stack->unlock if $stack->is_locked && $self->force;

    # NOTE: when we delete the stack, all the registrations will also be
    # deleted (via cascade), which will generate new registration_change 
    # records.  To prevent these changes from being recorded under the 
    # last revision, we must open the stack to create a new revision.  
    # But in the end, the revision will be deleted (via cascade) once 
    # the stack is gone.

    $self->repo->open_stack($stack);

    # TODO: Consider moving all the logic for creating/deleting stacks
    # and stack filesystems into a single method in the Repo class.
    
    $self->repo->delete_stack_filesystem(stack => $stack);

    $stack->delete;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
