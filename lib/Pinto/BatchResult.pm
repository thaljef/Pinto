package Pinto::BatchResult;

# ABSTRACT: The result from running a Batch of Actions

use Moose;

use MooseX::Types::Moose qw(Bool);

#-----------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has made_changes => (
    is        => 'ro',
    isa       => Bool,
    writer    => '_set_made_changes',
    default   => 0,
);

has is_success => (
    is         => 'ro',
    isa        => Bool,
    writer     => '_set_is_success',
    default    => 1,
);

#-----------------------------------------------------------------------------

sub failed {
    my ($self) = @_;
    $self->_set_is_success(0);
    return $self;
}

#-----------------------------------------------------------------------------

sub changed {
    my ($self) = @_;
    $self->_set_made_changes(1);
    return $self;
}

#-----------------------------------------------------------------------------
# TODO: Consolidate ActionResult and BatchResult into the same Result class
# and overload the &&= operator so you can merge them together like this:
#
# Result->new &&= $Result->new->failed
#
# Alternatively, consider accumulating each of the ActionResults in the
# BatchResult so you can poke around with them later.

sub aggregate {
    my ($self, $action_result) = @_;

    $self->changed if $action_result->made_changes;
    $self->failed  if not $action_result->is_success;

    return $self;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
