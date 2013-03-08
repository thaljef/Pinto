# ABSTRACT: Create a new empty stack

package Pinto::Action::New;

use Moose;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(StackName);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
);


has default => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my %attrs = (name => $self->stack);
    my $stack = $self->repo->create_stack(%attrs);

    $stack->set_properties($stack->default_properties);
    $stack->mark_as_default if $self->default;


    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
