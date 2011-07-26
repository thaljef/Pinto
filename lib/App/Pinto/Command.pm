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
  return $_[0]->app()->pinto();
}

#-----------------------------------------------------------------------------


1;

__END__
