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
        [ 'norecurse'   => 'Do not recursively import prereqs' ],
        [ 'pin'         => 'Pin packages to the stack' ],
        [ 'stack|s=s'   => 'Put packages into this stack' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS] ARCHIVE_FILE ...
%c --root=PATH $command [OPTIONS] < LIST_OF_ARCHIVE_FILES
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub args_attribute { return 'archives' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

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

=item --norecurse

Prevents L<Pinto> from recursively importing distributions required to
satisfy the prerequisites of the added distribution.  Imported
distributions are pulled from whatever remote repositories are
configured as the C<source> for this local repository.

=item --pin

Pins all the packages in the distribution to the stack, so they cannot
be changed until you unpin them.  The pin does not apply to any
prerequisites that are pulled in for this distribution.  However, you
may pin them separately with the C<pin> command, if you so desire.

=item --stack=NAME

Places all the packages within the distribution into the stack with
the given NAME.  Otherwise, packages go onto the 'default' stack.

=back

=cut
