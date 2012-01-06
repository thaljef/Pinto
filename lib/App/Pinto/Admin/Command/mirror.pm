package App::Pinto::Admin::Command::mirror;

# ABSTRACT: get all the latest distributions from another repository

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

=for stopwords MacBook

=head1 SYNOPSIS

  pinto-admin --root=/some/dir mirror [OPTIONS]

=head1 DESCRIPTION

This command pulls the latest versions of all distributions from your
source repositories (usually one or more CPAN mirrors) into your local
repository.  The URLs of the source repositories are defined in the
configuration file at F<.pinto/config/pinto.ini> inside your
repository.

The mirror process happens in two steps: First, the index of the
source repository is loaded into the local L<Pinto> database.  Second,
every (new) distribution from that source is downloaded into the local
L<Pinto> repository.  These steps are repeated for each source
repository.

Mirrors can take a while (see L</NOTES>) so if you're impatient,
you might consider using the C<--verbose> switch so you can see what
is going on.

=head1 COMMAND ARGUMENTS

None

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

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at NAME.
This is only relevant if you are using a VCS-based storage mechanism.
The syntax of the NAME depends on the type of VCS you are using.

=back

=head1 NOTES

The first time you pull from a CPAN mirror, it will take a few hours
to download and process all the distributions (over 25,000 of them).
And if you are using a VCS-based store then it will take even more
time to commit all that stuff.  On my MacBook Pro with a 20Mb
connection, it takes about 4 hours to do the whole job.  Yours may be
faster or slower, depending on the performance of your network and
disk.

But subsequent mirrors will be much, much faster.  If you mirror daily
(or even weekly) then the process should only take a few seconds.

=cut
