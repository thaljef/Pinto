# ABSTRACT: Register packages from existing archives on a stack

package Pinto::Action::Reindex;

use Moose;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Exception qw(throw);
use Pinto::Types qw(DistSpecList StackName StackDefault StackObject);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has targets   => (
    isa      => DistSpecList,
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


has pin => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------


sub execute {
    my ($self) = @_;

    my $stack    = $self->repo->get_stack($self->stack);
    my $old_head = $stack->head;
    my $new_head = $stack->start_revision;

    my @reindexed_dists = map { $self->_reindex($_, $stack) } $self->targets;
    return $self->result if $self->dryrun or $stack->has_not_changed;

    $self->generate_message_title('Reindexed', @reindexed_dists);
    $self->generate_message_details($stack, $old_head, $new_head);
    $stack->commit_revision(message => $self->edit_message);
    
    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _reindex {
    my ($self, $spec, $stack) = @_;

    my $dist  = $self->repo->get_distribution(spec => $spec);
    throw "Distribution $spec is not in the repository" if not defined $dist;

    $dist->register(stack => $stack, pin => $self->pin);

    return $dist;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
