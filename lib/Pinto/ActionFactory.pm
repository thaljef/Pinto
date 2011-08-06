package Pinto::ActionFactory;

# ABSTRACT: Factory class for making Actions

use Moose;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has idxmgr => (
    is       => 'ro',
    isa      => 'Pinto::IndexManager',
    required => 1,
);

has store => (
    is       => 'ro',
    isa      => 'Pinto::Store',
    required => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------
# Methods

sub create_action {
    my ($self, $action_name, %args) = @_;

    my $action_class = "Pinto::Action::$action_name";
    Class::Load::load_class( $action_class );

    return $action_class->new( config => $self->config(),
                               logger => $self->logger(),
                               idxmgr => $self->idxmgr(),
                               store  => $self->store(),
                               %args );

}

#------------------------------------------------------------------------------

__PACKAGE__->meta()->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
