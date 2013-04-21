package App::Pinto::Command::add;

# ABSTRACT: add local archives to the repository

use strict;
use warnings;

#------------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'author=s'     => 'Your (alphanumeric) author ID'       ],
        [ 'dry-run'      => 'Do not commit any changes'           ],
        [ 'message|m=s'  => 'Message to describe the change'      ],
        [ 'no-fail'      => 'Do not fail when there is an error'  ],
        [ 'no-recurse|n' => 'Do not recursively pull prereqs'     ],
        [ 'pin'          => 'Pin packages to the stack'           ],
        [ 'stack|s=s'    => 'Put packages into this stack'        ],
        [ 'use-default-message|M' => 'Use the generated message' ],
    );
}

#------------------------------------------------------------------------------

sub args_attribute { return 'archives' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT add [OPTIONS] ARCHIVE_FILE ...

=head1 DESCRIPTION

This command adds local distribution archives to the repository and
registers their packages on a stack. Then it recursively pulls all the 
distributions that are necessary to satisfy their prerequisites.

When locating prerequisites, Pinto first looks at the packages that
already exist in the local repository, then Pinto looks at the
packages that are available on the upstream repositories.

=head1 COMMAND ARGUMENTS

Arguments to this command are paths to the distribution archives that
you wish to add.  Each of these files must exist and must be readable.

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --author NAME

Set the identity of the distribution author.  The C<NAME> must be
alphanumeric characters plus hyphens and underscores.  Defaults to
the C<user> specified in your C<~/.pause> configuration file if such 
file exists.  Otherwise, defaults to your current login username.
By convention, author IDs are always folded to uppercase.

=item --dry-run

Go through all the motions, but do not actually commit any changes to
the repository.  Use this option to see how the command would
potentially impact the stack.

=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  If you do not use the
C<--message> option or the C<--use-default-message> option, then you
will be prompted to enter the message via your text editor.  Use the
C<EDITOR> or C<VISUAL> environment variables to control which editor
is used.  A log message is not required whenever the C<--dry-run>
option is set, or if the action did not yield any changes to the
repository.

=item --no-fail

!! THIS OPTION IS EXPERIMENTAL !!

Normally, failure to add an archive (or its prerequisites) causes the 
command to immediately abort and rollback the changes to the repository.  
But if C<--no-fail> is set, then only the changes caused by the failed
archive (and its prerequisites) will be rolled back and the command
will continue processing the remaining archives.

This option is useful if you want to throw a list of archives into
a repository and see which ones are problematic.  Once you've fixed
the broken ones, you can throw the whole list at the repository
again.

=item --no-recurse

=item -n

Do not recursively pull distributions required to satisfy the
prerequisites of the added archives.

=item --pin

Pins all the packages in the added distributions to the stack, so they
cannot be changed until you unpin them.  The pin does not apply to any
prerequisites that are pulled in for this distribution.  However, you
may pin them separately with the
L<pin|App::Pinto::Command::pin> command, if you so desire.

=item --stack NAME

=item -s NAME

Puts all the packages onto the stack with the given NAME.  Defaults
to the name of whichever stack is currently marked as the default
stack.  Use the L<stacks|App::Pinto::Command::stacks> command
to see the stacks in the repository.

=item --use-default-message

=item -M

Use the default value for the revision history log message.  Pinto
will generate a semi-informative log message just based on the command
and its arguments.  If you set an explicit message with C<--message>,
the C<--use-default-message> option will be silently ignored.

=back

=cut
