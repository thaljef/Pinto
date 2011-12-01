package App::Pinto::Admin::Command::verify;

# ABSTRACT: report distributions that are missing

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'noinit'    => 'Do not pull/update from VCS' ],
    );
}

#-----------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error("Arguments are not allowed") if @{ $args };

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_batch( %{$opts} );
    $self->pinto->add_action('Verify', %{$opts});
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --repos=/some/dir verify

=head1 DESCRIPTION

This command reports distributions that are listed in the index of
your repository, but the archives are not actually present.  This can
occur when L<Pinto> aborts unexpectedly due to an exception or you
terminate a command prematurely.  It can also happen when the index of
the source repository contains distributions that aren't actually
present in that repository (CPAN mirrors are known to do this
occasionally).

If some foreign distributions are missing from your repository, then
running a C<mirror> command will usually fix things.  If local
distributions are missing, then you need to get a copy of that
distribution use the C<add> command to put it back in the repository.
Or, you can just use the C<remove> command to delete the local
distribution from the index if you no longer care about it.

Note this command never changes the state of your repository.

=head1 COMMAND ARGUMENTS

None

=head1 COMMAND OPTIONS

None


=cut
