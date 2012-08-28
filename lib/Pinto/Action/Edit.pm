# ABSTRACT: Change stack properties

package Pinto::Action::Edit;

use Moose;
use MooseX::Types::Moose qw(Undef Str HashRef Bool);

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName | Undef,
    default  => undef,
    coerce   => 1,
);


has properties => (
    is      => 'ro',
    isa     => HashRef,
    default => sub{ {} },
);


has default => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);
    $stack->mark_as_default if $self->default;
    $stack->set_properties($self->properties);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
