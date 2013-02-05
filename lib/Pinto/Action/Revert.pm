# ABSTRACT: Restore stack to a prior revision

package Pinto::Action::Revert;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Patch;
use Pinto::Types qw(StackName StackDefault StackObject CommitID);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);


has commit => (
    is       => 'ro',
    isa      => CommitID,
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);

    my $diff  = $self->repo->vcs->diff( left_commit_id => $stack->last_commit_id,
                                        right_commit_id => $self->commit );

    my $patch = Pinto::Patch->new(diff => $diff, stack => $stack);
    $patch->apply;

    return $self->result if $self->dryrun or $stack->has_not_changed;

    my $message = $self->edit_message(stack => $stack);
    $stack->commit(message => $message);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $commit = $self->commit;

    return "Reverted to commit $commit.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
