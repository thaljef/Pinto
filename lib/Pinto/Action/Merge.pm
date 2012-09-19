# ABSTRACT: Merge packages from one stack into another

package Pinto::Action::Merge;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Pinto::Types qw(StackName);

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
    isa      => StackName,
    required => 1,
    coerce   => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $from_stack = $self->repos->get_stack(name => $self->from_stack);
    my $to_stack   = $self->repos->open_stack(name => $self->to_stack);

    $self->notice("Merging stack $from_stack into stack $to_stack");

    $from_stack->merge(to => $to_stack);
    $self->result->changed if $to_stack->refresh->has_changed;

    if ( not ($self->dryrun and $to_stack->has_changed) ) {
        my $message_primer = $to_stack->head_revision->change_details;
        my $message = $self->edit_message(primer => $message_primer);
        $to_stack->close(message => $message, committed_by => $self->username);
        $self->repos->write_index(stack => $to_stack);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
