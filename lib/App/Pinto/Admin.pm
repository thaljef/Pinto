package App::Pinto::Admin;

# ABSTRACT: Command-line driver for Pinto

use strict;
use warnings;

use App::Cmd::Setup -app;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub global_opt_spec {

  return (
      [ 'repos|r=s'   => 'Path to your repository directory' ],
      [ 'nocolor'     => 'Do not colorize diagnostic messages' ],
      [ 'quiet|q'     => 'Only report fatal errors' ],
      [ 'verbose|v+'  => 'More diagnostic output (repeatable)' ],
  );
}

#------------------------------------------------------------------------------

sub usage_desc {
    return '%c [global options] <command> [command options]';
}

#------------------------------------------------------------------------------

=method pinto()

Returns a reference to the L<Pinto> object.  If it does not already
exist, one will be created using the global options.

=cut

sub pinto {
    my ($self) = @_;

    return $self->{pinto} ||= do {

        my %global_options = %{ $self->global_options() };

        $global_options{repos}
            or $self->usage_error('Must specify a repository');

        require Pinto;
        my $pinto  = Pinto->new(%global_options);
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
