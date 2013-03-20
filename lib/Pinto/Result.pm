package Pinto::Result;

# ABSTRACT: The result from running an Action

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

#-----------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has made_changes => (
    is        => 'ro',
    isa       => Bool,
    writer    => '_set_made_changes',
    default   => 0,
);



has was_successful => (
    is         => 'ro',
    isa        => Bool,
    writer     => '_set_was_successful',
    default    => 1,
);

#-----------------------------------------------------------------------------

sub failed {
    my ($self) = @_;
    $self->_set_was_successful(0);
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
    return $self->was_successful ? 0 : 1;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
