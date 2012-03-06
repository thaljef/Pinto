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

    # Create new stack
    # Copy existing package_stack to new stack

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

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
