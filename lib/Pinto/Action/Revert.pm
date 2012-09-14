# ABSTRACT: Restore stack to a prior revision

package Pinto::Action::Revert;

use Moose;
use MooseX::Types::Moose qw(Int);

use Pinto::Types qw(StackName StackDefault);

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
    is        => 'ro',
    isa       => Int,
    required  => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $DB::single = 1;
    my $stack   = $self->repos->get_stack(name => $self->stack);
    my $headnum = $stack->head_revision->number;

    my $revnum  = $self->revision;
    $revnum     = ($headnum + $revnum) if $revnum < 0;

    $self->fatal("No such revision $revnum on stack $stack")
      if $revnum > $headnum;

    $self->fatal("Revision $revnum is the head of stack $stack")
      if $revnum == $headnum;

    my $new_head  = $self->repos->open_revision(stack => $stack);
    my $previous_revision = $new_head->previous_revision;



    while ($previous_revision->number > $revnum) {
        $previous_revision->undo;
        $previous_revision = $previous_revision->previous_revision;
    }

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
