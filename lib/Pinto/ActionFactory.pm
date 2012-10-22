# ABSTRACT: Construct Action objects

package Pinto::ActionFactory;

use Moose;
use MooseX::Types::Moose qw(Str);

use Class::Load;

use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has repo  => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);


has action_class_namespace => (
    is        => 'ro',
    isa       => Str,
    default   => 'Pinto::Action',
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

sub create_action {
    my ($self, $action_name, %action_args) = @_;

    @action_args{qw(config logger repo)} = ($self->config, $self->logger, $self->repo);
    my $action_class = $self->load_class_for_action(name => $action_name);
    my $action = $action_class->new(%action_args);

    return $action;
}

#------------------------------------------------------------------------------

sub load_class_for_action {
    my ($self, %args) = @_;

    my $action_name = ucfirst $args{name} || throw 'Must specify an action name';
    my $action_class = $self->action_class_namespace . '::' . $action_name;
    Class::Load::load_class($action_class);

    return $action_class;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
