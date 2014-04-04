# ABSTRACT: Create a new stack by copying another

package Pinto::Action::Copy;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Types qw(StackName StackObject);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);

has to_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
);

has default => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has lock => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has description => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_description',
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my %changes = ( name => $self->to_stack );
    my $orig    = $self->repo->get_stack( $self->stack );
    my $copy    = $self->repo->copy_stack( stack => $orig, %changes );

    my $description =
          $self->has_description
        ? $self->description
        : "Copy of stack $orig";

    $copy->set_description($description);
    $copy->mark_as_default if $self->default;
    $copy->lock            if $self->lock;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
