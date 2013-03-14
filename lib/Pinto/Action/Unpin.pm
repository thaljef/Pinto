# ABSTRACT: Loosen a package that has been pinned

package Pinto::Action::Unpin;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(SpecList StackName StackDefault StackObject);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has targets => (
    isa      => SpecList,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);


has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack    = $self->repo->get_stack($self->stack);
    my $old_head = $stack->head;
    my $new_head = $stack->start_revision;

    $DB::single = 1;
    my @unpinned_dists = map { $self->_unpin($_, $stack) } $self->targets;
    return $self->result if $self->dry_run or $stack->has_not_changed;

    $self->generate_message_title('Unpinned', @unpinned_dists);
    $self->generate_message_details($stack, $old_head, $new_head);
    $stack->commit_revision(message => $self->edit_message);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _unpin {
    my ($self, $target, $stack) = @_;

    my $dist = $stack->get_distribution(spec => $target);

    throw "$target is not registered on stack $stack" if not defined $dist;

    $self->notice("Unpinning distribution $dist from stack $stack");

    $dist->unpin(stack => $stack);

    return $dist;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
