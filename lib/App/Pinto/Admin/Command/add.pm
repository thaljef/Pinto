package App::Pinto::Admin::Command::add;

# ABSTRACT: add local distributions to the repository

use strict;
use warnings;

use Pinto::Util;

#------------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub command_names { return qw( add inject ) }

#-----------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'author=s'    => 'Your (alphanumeric) author ID' ],
        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'norecurse'   => 'Do not recursively import prereqs' ],
        [ 'pin=s'       => 'Pin all added packages to the stack' ],
        [ 'stack|s=s'   => 'Put packages into this stack' ],
        [ 'tag=s'       => 'Specify a VCS tag name' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS] ARCHIVE_FILE_OR_URL ...
%c --root=PATH $command [OPTIONS] < LIST_OF_ARCHIVE_FILES_OR_URLS
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my @args = @{$args} ? @{$args} : Pinto::Util::args_from_fh(\*STDIN);
    return 0 if not @args;

    $self->pinto->new_batch(%{$opts});
    $self->pinto->add_action($self->action_name(), %{$opts}, archive => $_) for @args;
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --root=/some/dir add [OPTIONS] ARCHIVE_FILE_OR_URL ...
  pinto-admin --root=/some/dir add [OPTIONS] < LIST_OF_ARCHIVE_FILES_OR_URLS

=head1 DESCRIPTION

This command adds a local distribution archive and all its packages to
the repository and recomputes the 'latest' version of the packages
that were in that distribution.

By default, Pinto also recursively imports all the distributions that
are required to provide the prerequisite packages for the newly added
distribution.  When searching for those prerequisite packages, Pinto first
looks at the the packages that already exist in the local repository,
then Pinto looks at the packages that are available available on the
remote repositories.  At present, Pinto takes the *first* package it
can find that satisfies the prerequisite.  In the future, you may be
able to direct Pinto to instead choose the *latest* package that
satisfies the prerequisite (NOT SURE THOSE LAST TWO STATEMENTS ARE TRUE).

Imported distributions will be assigned to their original author, not
the author who added the distribution that triggered the import.

=head1 COMMAND ARGUMENTS

Arguments to this command are paths to the distribution files that you
wish to add.  Each of these files must exist and must be readable.  If
a path looks like a URL, then the distribution first retrieved
from that URL and stored in a temporary file, which is subsequently
added.

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --author=NAME

Sets your identity as a distribution author.  The C<NAME> must be
alphanumeric characters (no spaces) and will be forced to uppercase.
Defaults to the C<user> specified in your C<~/.pause> configuration
file (if such file exists).  Otherwise, defaults to your current login
username.

=item --message=MESSAGE

Prepends the MESSAGE to the VCS log message that L<Pinto> generates.
This is only relevant if you are using a VCS-based storage mechanism
for L<Pinto>.

=item --nocommit

Prevents L<Pinto> from committing changes in the repository to the VCS
after the operation.  This is only relevant if you are
using a VCS-based storage mechanism.  Beware this will leave your
working copy out of sync with the VCS.  It is up to you to then commit
or rollback the changes using your VCS tools directly.  Pinto will not
commit old changes that were left from a previous operation.

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=item --norecurse

Prevents L<Pinto> from recursively importing distributions required to
satisfy the prerequisites of the added distribution.  Imported
distributions are pulled from whatever remote repositories are
configured as the C<source> for this local repository.

=item --pin=REASON

Pins all the packages in the distribution to the stack, so they cannot
be changed until you unpin them.  The C<REASON> is a brief description
of why want to pin these packages.

=item --stack=NAME

Instructs L<Pinto> to place all the packages within the distribution
into the stack with the given NAME.   All packages are always placed
in the C<default> stack as well.

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at NAME.
This is only relevant if you are using a VCS-based storage mechanism.
The syntax of the NAME depends on the type of VCS you are using.

=back

=cut
