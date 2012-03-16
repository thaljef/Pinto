package Pinto::Action::Stack::Copy;

# ABSTRACT: An action to create a new stack by copying another

use Moose;

use MooseX::Types::Moose qw(Str);
use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attributes

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


has description => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_description',
);

#------------------------------------------------------------------------------
# Methods

override execute => sub {
    my ($self) = @_;

    my $txn_guard = $self->repos->db->schema->txn_scope_guard(); # BEGIN transaction

    my $from_stack = $self->_check_stacks();
    my $to_stack   = $self->_copy_stack($from_stack);
    $self->_copy_stack_members($from_stack, $to_stack);

    $txn_guard->commit(); #END transaction

    return 1;
};

#------------------------------------------------------------------------------

sub _check_stacks {
    my ($self) = @_;

    my $from_stack_name = $self->from_stack();
    my $from_stack = $self->repos->get_stack( name => $from_stack_name )
        or $self->fatal("Source stack $from_stack_name does not exist");

    my $to_stack_name = $self->to_stack();
    $self->repos->get_stack( name => $to_stack_name )
        and $self->fatal("Target stack $to_stack_name already exists");

    return $from_stack;
}

#------------------------------------------------------------------------------

sub _copy_stack {
    my ($self, $from_stack) = @_;

    $self->note( sprintf 'Creating new stack %s', $self->to_stack() );

    my $changes = { name => $self->to_stack() };
    $changes->{description} = $self->description() if $self->has_description();
    my $to_stack = $from_stack->copy( $changes );

    return $to_stack;
}

#------------------------------------------------------------------------------

sub _copy_stack_members {
    my ($self, $from_stack, $to_stack) = @_;

    $self->note("Copying stack $from_stack into stack $to_stack");

    for my $packages_stack ( $from_stack->packages_stack() ) {
        $self->debug(sprintf 'Copying package %s into stack %s', $packages_stack->package(), $to_stack);
        $packages_stack->copy( { stack => $to_stack->id() } );
    }

    # TODO: Make sure both stacks have the same mtime after copying

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
