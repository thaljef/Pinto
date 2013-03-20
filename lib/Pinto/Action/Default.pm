# ABSTRACT: Set the default stack

package Pinto::Action::Default;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(StackName StackObject);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
);


has none => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

   	if ($self->none) {
   		my $default_stack = $self->repo->get_stack;
      return $self->result if not defined $default_stack;
      $default_stack->unmark_as_default;

   	}
   	else {
    	my $stack = $self->repo->get_stack($self->stack);
      return $self->result if $stack->is_default;
      $stack->mark_as_default;
	  }
  
    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
