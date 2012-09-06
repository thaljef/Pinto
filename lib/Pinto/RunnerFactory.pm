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
    my $runner_class = $self->load_class_for_runner($action);
    my $runner = $runner_class->new(repos => $self->repos, logger => $self->logger);

    return $runner;
}

#------------------------------------------------------------------------------

sub load_class_for_runner {
    my ($self, $action) = @_;

    my $runner_class;

    $runner_class = 'Pinto::Runner::Transactional'
      if $action->does('Pinto::Role::Action::Transactional');

    $runner_class = 'Pinto::Runner::NonTransactional'
      if $action->does('Pinto::Role::Action::NonTransactional');

    throw "Don't know how to run action $action" if not $runner_class;

    Class::Load::load_class($runner_class);

    return $runner_class;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
