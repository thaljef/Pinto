package App::Pinto;

# ABSTRACT: Command-line driver for Pinto

use strict;
use warnings;

use parent 'Pinto';
use App::Cmd::Setup -app;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
#
# TODO: Consider moose-ifying this class
#
#------------------------------------------------------------------------------

sub global_opt_spec {
  return (
    [ "verbose"   => "Log additional output" ],
    [ "local=s"   => "Path to local repository directory"],
    [ "profile=s" => "Path to your pinto profile" ],
  );
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 DESCRIPTION

There is nothing to see here.  You probably should look at the
documentation for L<pinto> instead.

=cut
