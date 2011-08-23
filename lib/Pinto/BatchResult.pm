package Pinto::BatchResult;

# ABSTRACT: Accumulates exceptions and status from an ActionBatch

use Moose;

use MooseX::Types::Moose qw(Bool ArrayRef);

#-----------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has changes_made    => (
    is        => 'ro',
    isa       => Bool,
    init_arg  => undef,
    writer    => '_set_changes_made',
    default   => 0,
);

has exceptions => (
    is         => 'ro',
    isa        => ArrayRef,
    traits     => [ 'Array' ],
    default    => sub { [] },
    handles    => {add_exception => 'push'},
    init_arg   => undef,
    auto_deref => 1,
);

#-----------------------------------------------------------------------------
# TODO: Should we have an "ActionResult" to go with our "BatchResult" too?

sub is_success {
    my ($self) = @_;

    return @{ $self->exceptions } == 0;
}

#-----------------------------------------------------------------------------
# HACK! Confusing: "made_changes" vs. "changes_made"

sub made_changes {
    my ($self) = @_;

    $self->_set_changes_made(1);

    return $self;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
