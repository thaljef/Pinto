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

    $self->_check_stacks();  # Maybe do this in the BUILD?

    my $txn_guard = $self->repos->db->schema->txn_scope_guard(); # BEGIN transaction

    $self->_copy_stack();
    $self->_fill_stack();

    $txn_guard->commit(); #END transaction

    return 1;
};

#------------------------------------------------------------------------------

sub _check_stacks {
    my ($self) = @_;

    my $from_stack_name = $self->from_stack();
    my $from_where = {name => $from_stack_name};
    $self->repos->db->select_stacks( $from_where )->single()
        or $self->fatal("Source stack $from_stack_name does not exist");

    my $to_stack_name = $self->to_stack();
    my $to_where = {name => $to_stack_name};
    $self->repos->db->select_stacks( $to_where )->single()
        and $self->fatal("Target stack $to_stack_name already exists");

    return;
}

#------------------------------------------------------------------------------

sub _copy_stack {
    my ($self) = @_;

    $self->note( sprintf 'Creating new stack %s', $self->to_stack() );

    my $from_stack_name = $self->from_stack();
    my $from_where = {name => $from_stack_name};
    my $stack = $self->repos->db->select_stacks( $from_where )->single()
        or $self->fatal("Source stack $from_stack_name does not exist");

    my $changes = { name => $self->to_stack() };
    $changes->{description} = $self->description() if $self->has_description();
    $stack->copy( $changes );

    return;
}

#------------------------------------------------------------------------------

sub _fill_stack {
    my ($self) = @_;

    my $from_stack_name = $self->from_stack();
    my $from_stack = $self->repos->db->select_stacks( {name => $from_stack_name} )->single()
        or confess "Stack $from_stack_name does not exist";

    my $to_stack_name = $self->to_stack();
    my $to_stack = $self->repos->db->select_stacks( {name => $to_stack_name} )->single()
        or confess "Stack $to_stack_name does not exist";

    my $where = { stack => $from_stack->id() };
    my $package_stack_rs = $self->repos->db->select_package_stack( $where );

    $self->note("Copying stack $from_stack into stack $to_stack");

    while ( my $package_stack = $package_stack_rs->next() ) {
        $self->debug(sprintf 'Copying package %s into stack %s', $package_stack->package(), $to_stack);
        $package_stack->copy( { stack => $to_stack->id() } );
    }

    # TODO: Make sure both stacks have the same mtime after copying

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
