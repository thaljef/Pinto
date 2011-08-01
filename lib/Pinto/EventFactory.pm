package Pinto::EventFactory;

# ABSTRACT: Factory class for making Events

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

sub create_event {
    my ($self, $event, %args) = @_;

    my $event_class = "Pinto::Event::$event";
    Class::Load::load_class( $event_class );

    return $event_class->new( config => $self->config(),
                              logger => $self->logger(),
                              idxmgr => $self->idxmgr(),
                              %args );

}

#------------------------------------------------------------------------------

1;

__END__
