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
        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'recompute'   => 'Also recompute latest versions' ],
        [ 'tag=s'       => 'Specify a VCS tag name' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Arguments are not allowed') if @{ $args };

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 SYNOPSIS

  pinto-admin --repos=/some/dir rebuild [OPTIONS]

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

Prepends the MESSAGE to the VCS log message that L<Pinto> generates.
This is only relevant if you are using a VCS-based storage mechanism
for L<Pinto>.

=item --nocommit

Prevents L<Pinto> from committing changes in the repository to the VCS
after the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  Beware this will leave your working copy
out of sync with the VCS.  It is up to you to then commit or rollback
the changes using your VCS tools directly.  Pinto will not commit old
changes that were left from a previous operation.

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=item --recompute

Instructs L<Pinto> to also recompute what it thinks is the 'latest'
version of each package in the repository.  This is useful if you've
upgraded to a newer version of Pinto that has different (hopefully
better) logic for determining the 'latest' version.

Beware that the C<--recompute> option could change the contents of the
index file, thereby affecting which packages clients will pull from
the repository.  And if you subsequently run the C<clean> command, you
will loose the distributions that were in the old index, but are not
in the new one.

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at NAME.
This is only relevant if you are using a VCS-based storage mechanism.
The syntax of the NAME depends on the type of VCS you are using.

=back

=cut
