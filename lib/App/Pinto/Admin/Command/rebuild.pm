package App::Pinto::Admin::Command::rebuild;

# ABSTRACT: rebuild the repository index

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'message|m=s' => 'Message for the revision log' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Arguments are not allowed') if @{ $args };

    return 1;
}

#------------------------------------------------------------------------------
# TODO this command may be completely useless now that we have stacks.
#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --root=/some/dir rebuild [OPTIONS]

=head1 DESCRIPTION

In the event your index file becomes corrupt or goes missing, you can
use this command to rebuild it.  Note this is not the same as
re-indexing all your distributions.  Rebuilding the index simply means
regenerating the index file from the information that L<Pinto> already
has about your distributions.

You might also want to rebuild the index after upgrading to a new
version of L<Pinto>.  Newer versions may correct or improve the way
the latest version of a package is calculated.  See the C<--recompute>
option below.

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

=over 4

=item --message=MESSAGE

Use the given MESSAGE as the revision log message.

=back

=cut
