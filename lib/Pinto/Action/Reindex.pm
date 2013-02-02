# ABSTRACT: Register packages from existing archives on a stack

package Pinto::Action::Reindex;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Pinto::Exception qw(throw);
use Pinto::Types qw(DistSpecList StackName StackDefault StackObject);

use namespace::autoclean;

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

    my $stack = $self->repo->get_stack($self->stack);
    $self->_reindex($_, $stack) for $self->targets;

    return $self->result if $self->dryrun or $stack->has_not_changed;

    my $message = $self->edit_message(stack => $stack);
    $stack->commit(message => $message);
    
    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _reindex {
    my ($self, $target, $stack) = @_;

    my $dist  = $self->repo->get_distribution(spec => $target);
    throw "Distribution $target is not in the repository" if not defined $dist;

    $stack->register(distribution => $dist, pin => $self->pin);

    return;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $targets  = join ' ', $self->targets;
    my $pinned   = $self->pin ? ' and pinned' : '';

    return "Reindexed$pinned $targets.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
