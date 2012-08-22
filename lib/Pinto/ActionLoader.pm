# ABSTRACT: Load Action classes

package Pinto::ActionLoader;

use Moose;
use MooseX::Types::Moose qw(Str);

use Class::Load;

use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has action_class_namespace => (
    is        => 'ro',
    isa       => Str,
    default   => 'Pinto::Action',
);

#------------------------------------------------------------------------------

sub load_action {
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
