# ABSTRACT: Merge by moving the head pointer

package Pinto::Merger::FastForward;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Exception qw(throw);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw(Pinto::Merger);

#-----------------------------------------------------------------------------

sub merge {
    my ($self) = @_;

    $self->repo->vcs->checkout_branch(name => $self->to_stack);
    $self->repo->vcs->reset(commit => $self->from_stack->last_commit_id);
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__