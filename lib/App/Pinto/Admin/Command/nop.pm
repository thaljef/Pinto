package App::Pinto::Admin::Command::nop;

# ABSTRACT: initialize Pinto and exit

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'sleep=i' => 'seconds to sleep before exiting' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->SUPER::validate_args(@_);

    $self->usage_error('Sleep time must be positive integer')
      if defined $opts->{sleep} && $opts->{sleep} < 1;

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 SYNOPSIS

  pinto-admin --root=/some/dir nop [OPTIONS]

=head1 DESCRIPTION

This command is a no-operation.  It locks and initializes the
repository, but does not perform any operations.  This is really only
used for diagnostic purposes.  So don't worry about it too much.

Note this command never changes the state of your repository.

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

=item --sleep=N

Directs L<Pinto> to sleep for N seconds before releasing the lock and
exiting.  Default is 0.

=back

=cut
