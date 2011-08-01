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
    builder  => '__build_idxmgr',
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw(Pinto::Role::Configurable Pinto::Role::Loggable);

#------------------------------------------------------------------------------
# Builders

sub __build_idxmgr {
    my ($self) = @_;

    return Pinto::IndexManager->new( config => $self->config(),
                                     logger => $self->logger() );
}

#------------------------------------------------------------------------------
# Methods

sub create_action {
    my ($self, $action_name, %args) = @_;

    my $action_class = "Pinto::Action::$action_name";
    Class::Load::load_class( $action_class );

    return $action_class->new( config => $self->config(),
                              logger => $self->logger(),
                              idxmgr => $self->idxmgr(),
                              %args );

}

#------------------------------------------------------------------------------

1;

__END__
