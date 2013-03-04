# ABSTRACT: Force a package to stay in a stack

package Pinto::Action::Pin;

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

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);


has targets => (
    isa      => SpecList,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack)->start_revision;
    $self->_pin($_, $stack) for $self->targets;

    return $self->result if $self->dryrun or $stack->has_not_changed;

    my $message = $self->edit_message(stack => $stack);
    $stack->commit_revision(message => $message);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _pin {
    my ($self, $target, $stack) = @_;

    $DB::single = 1;
    my $dist = $stack->get_distribution(spec => $target);

    throw "$target is not registered on stack $stack" if not defined $dist;

    $self->notice("Pinning distribution $dist to stack $stack");

    $dist->pin(stack => $stack);

    return;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $targets  = join ', ', $self->targets;

    return "Pinned ${targets}.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
