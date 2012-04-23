# ABSTRACT: Merge packages from one stack into another

package Pinto::Action::Stack::Merge;

use Moose;
use MooseX::Types::Moose qw(Bool);

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


has dryrun => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self, $args) = @_;

    my $from_stk_name = $self->from_stack;
    $self->fatal("Stack $from_stk_name does not exist")
        if not $self->repos->get_stack(name => $from_stk_name);

    my $to_stk_name = $self->to_stack;
    $self->fatal("Stack $to_stk_name does not exist")
        if not $self->repos->get_stack(name => $to_stk_name);

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $from_stk_name = $self->from_stack;
    my $to_stk_name = $self->to_stack;

    $self->notice("Merging stack $from_stk_name into stack $to_stk_name");

    my $did_merge = $self->repos->merge_stack( from   => $self->from_stack,
                                               to     => $self->to_stack,
                                               dryrun => $self->dryrun );

    $self->result->changed unless $self->dryrun;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
