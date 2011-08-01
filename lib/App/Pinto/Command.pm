package App::Pinto::Command;

# ABSTRACT: Base class for pinto commands

use strict;
use warnings;

#-----------------------------------------------------------------------------

use App::Cmd::Setup -command;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

=method pinto()

Returns the Pinto object for this command.  Basically an alias for

  $self->app();

=cut

sub pinto {
  my ($self, $options) = @_;
  return $self->app()->pinto($options);
}

#-----------------------------------------------------------------------------


1;

__END__
