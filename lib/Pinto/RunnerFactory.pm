# ABSTRACT: Construct Runner objects

package Pinto::RunnerFactory;

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has repos => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);


has runner_class_namespace => (
    is        => 'ro',
    isa       => Str,
    default   => 'Pinto::Runner',
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

sub create_runner {
    my ($self, %args) = @_;

    my $action = $args{action};
    my $runner_class = $self->load_class_for_runner(name => $action->runner);
    my $runner = $runner_class->new(repos => $self->repos, logger => $self->logger);

    return $runner;
}

#------------------------------------------------------------------------------

sub load_class_for_runner {
    my ($self, %args) = @_;

    my $runner_name = ucfirst $args{name} || throw 'Must specify an action name';
    my $runner_class = $self->runner_class_namespace . '::' . $runner_name;
    Class::Load::load_class($runner_class);

    return $runner_class;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
