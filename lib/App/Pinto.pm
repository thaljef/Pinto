package App::Pinto;

# ABSTRACT: Command-line driver for Pinto

use strict;
use warnings;

use App::Cmd::Setup -app;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub global_opt_spec {

  return (

      [ "local=s"     => "Path to local repository directory"],
      [ "log_level=i" => "Set the amount of noise (0|1|2)" ],
      [ "nocleanup"   => "Do not clean repository after each action" ],
      [ "profile=s"   => "Path to your pinto profile" ],
  );
}

#------------------------------------------------------------------------------

sub usage_desc {
    return '%c [global options] <command>';
}

#------------------------------------------------------------------------------

=method pinto( $command_options )

Returns a reference to the L<Pinto> object.  If it does not already
exist, one will be created using the global and command options.

=cut

sub pinto {
    my ($self, $command_options) = @_;

    require Pinto;
    require Pinto::Config;
    require Pinto::Logger;

    return $self->{pinto} ||= do {
        my %global_options = %{ $self->global_options() };
        my $config = Pinto::Config->new(%global_options, %{$command_options});
        my $logger = Pinto::Logger->new(config => $config);
        my $pinto  = Pinto->new(config => $config, logger => $logger);
    };
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 DESCRIPTION

There is nothing to see here.  You probably should look at the
documentation for L<pinto> instead.

=cut
