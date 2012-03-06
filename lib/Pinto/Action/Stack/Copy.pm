package Pinto::Action::Stack::Copy;

# ABSTRACT: An action to create a new stack by copying another stack

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
    is      => 'ro',
    isa     => Str,
    default => 'no description was given',
);

#------------------------------------------------------------------------------
# Methods

override execute => sub {
    my ($self) = @_;

    $self->_check_stacks();  # Maybe doe this in the BUILD?

    my $txn_guard = $self->repos->db->schema->txn_scope_guard(); # BEGIN transaction

    $self->_create_stack();
    $self->_copy_stack();

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
        and $self->fatal("Destination stack $to_stack_name already exists");

    return;
}

#------------------------------------------------------------------------------

sub _create_stack {
    my ($self) = @_;

    my $struct = { name        => $self->to_stack(),
                   description => $self->description() };

    $self->repos->db->create_stack( $struct );

    return;
}

#------------------------------------------------------------------------------

sub _copy_stack {
    my ($self) = @_;

    my $from_stack_name = $self->from_stack();
    my $from_stack = $self->repos->db->select_stack( {name => $from_stack_name} )
        or confess "Stack $from_stack_name does not exist";

    my $to_stack_name = $self->to_stack();
    my $to_stack = $self->repos->db->select_stack( {name => $to_stack_name} )
        or confess "Stack $to_stack_name does not exist";

    my $where = { stack => $from_stack->id() };
    my $package_stack_rs = $self->repos->db->select_package_stack( $where );

    while ( my $package_stack = $package_stack_rs->next() ) {
        $package_stack->copy( { stack => $to_stack->id() } );
    }

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
