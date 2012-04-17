package Pinto::Action::Stack::Create;

# ABSTRACT: An action to create a new empty stack

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

has stack => (
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

sub execute {
    my ($self) = @_;

    my $stack_name = $self->stack();
    my $where = {name => $stack_name};

    $self->repos->db->select_stacks( $where )->single()
        and $self->fatal("Stack $stack_name already exists");

    $where->{description} = $self->description();

    $self->info("Creating stack $stack_name");

    $self->repos->db->create_stack( $where );

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
