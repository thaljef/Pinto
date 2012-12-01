# ABSTRACT: Merge packages from one stack into another

package Pinto::Action::Merge;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Pinto::Types qw(StackName StackObject);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has from_stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $from_stack = $self->repo->get_stack($self->from_stack);
    my $to_stack   = $self->repo->open_stack($self->to_stack);

    $self->notice("Merging stack $from_stack into stack $to_stack");

    my $did_merge = $from_stack->merge(to => $to_stack);
    $self->result->changed if $did_merge;

    if ($did_merge and not $self->dryrun) {
        my $message = $self->edit_message(stacks => [$to_stack]);
        $to_stack->close(message => $message);
        $self->repo->write_index(stack => $to_stack);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $from = $self->repo->get_stack($self->from_stack);
    my $into = $self->repo->get_stack($self->to_stack);

    return "Merged stack $from into stack $into.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
