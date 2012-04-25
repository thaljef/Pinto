package Pinto::Result;

# ABSTRACT: The result from running an Action

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


# TODO: rename to "was_success"

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

sub exit_status {
    my ($self) = @_;
    return not $self->is_success;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
