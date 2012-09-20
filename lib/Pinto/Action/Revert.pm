# ABSTRACT: Restore stack to a prior revision

package Pinto::Action::Revert;

use Moose;
use MooseX::Types::Moose qw(Int);

use Pinto::Types qw(StackName StackDefault);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault,
    default   => undef,
    coerce    => 1,
);


has revision => (
    is       => 'ro',
    isa      => Int,
    default  => -1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack   = $self->repos->get_stack(name => $self->stack);
    my $revnum  = $self->_compute_target_revnum($stack);

    $self->_execute($stack, $revnum);
    $self->result->changed if $stack->refresh->has_changed;

    if ($stack->has_changed and not $self->dryrun) {
        my $message_primer = $stack->head_revision->change_details;
        my $message = $self->edit_message(primer => $message_primer);
        $stack->close(message => $message, committed_by => $self->username);
        $self->repos->write_index(stack => $stack);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub _compute_target_revnum {
    my ($self, $stack) = @_;

    my $headnum = $stack->head_revision->number;

    my $revnum  = $self->revision;
    $revnum     = ($headnum + $revnum) if $revnum < 0;

    $self->fatal("Stack $stack is already at revision 0")
      if $headnum == 0;

    $self->fatal("No such revision $revnum on stack $stack")
      if $revnum > $headnum;

    $self->fatal("Revision $revnum is the head of stack $stack")
      if $revnum == $headnum;

    return $revnum;
}

#------------------------------------------------------------------------------

sub _execute {
    my ($self, $stack, $revnum) = @_;

    $self->notice("Reverting stack $stack to revision $revnum");

    my $new_head  = $self->repos->open_revision(stack => $stack);
    my $previous_revision = $new_head->previous_revision;

    while ($previous_revision->number > $revnum) {
        $previous_revision->undo;
        $previous_revision = $previous_revision->previous_revision;
    }

    throw "Checksum does not match for revision $revnum.  Aborting"
        if $previous_revision->md5 ne $new_head->compute_md5;

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
