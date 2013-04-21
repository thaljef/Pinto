# ABSTRACT: pull archives from upstream repositories

package App::Pinto::Command::pull;

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
        [ 'dry-run'      => 'Do not commit any changes'           ],
        [ 'message|m=s'  => 'Message to describe the change'      ],
        [ 'no-fail'      => 'Do not fail when there is an error'  ],
        [ 'no-recurse|n' => 'Do not recursively pull prereqs'     ],
        [ 'pin'          => 'Pin the packages to the stack'       ],
        [ 'stack|s=s'    => 'Put packages into this stack'        ],
        [ 'use-default-message|M' => 'Use the generated message' ],
    );
}

#------------------------------------------------------------------------------

sub args_attribute { return 'targets' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------

1;

__END__

=for stopwords norecurse

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT pull [OPTIONS] TARGET ...

=head1 DESCRIPTION

This command locates packages in your upstream repositories and then
pulls the distributions providing those packages into your repository
and registers them on a stack.  Then it recursively locates and pulls 
all the distributions that are necessary to satisfy their prerequisites.  
You can also request to directly pull particular distributions.

When locating prerequisites, Pinto first looks at the packages that
already exist in the local repository, then Pinto looks at the
packages that are available on the upstream repositories.

=head1 COMMAND ARGUMENTS

Arguments are the targets that you want to pull.  Targets can be
specified as packages (with or without a minimum version number) or
a distributions.  For example:

  Foo::Bar                                 # Pulls any version of Foo::Bar
  Foo::Bar~1.2                             # Pulls Foo::Bar 1.2 or higher
  SHAKESPEARE/King-Lear-1.2.tar.gz         # Pulls a specific distribuion
  SHAKESPEARE/tragedies/Hamlet-4.2.tar.gz  # Ditto, but from a subdirectory

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --dry-run

Go through all the motions, but do not actually commit any changes to
the repository.  Use this option to see how upgrades would potentially
impact the stack.

=item --no-fail

!! THIS OPTION IS EXPERIMENTAL !!

Normally, failure to pull a target (or its prerequisites) causes the 
command to immediately abort and rollback the changes to the repository.  
But if C<--no-fail> is set, then only the changes caused by the failed
target (and its prerequisites) will be rolled back and the command
will continue processing the remaining targets.

This option is useful if you want to throw a list of targets into
a repository and see which ones are problematic.  Once you've fixed
the broken ones, you can throw the whole list at the repository
again.

=item --no-recurse

=item -n

Do not recursively pull any distributions required to satisfy
prerequisites for the targets.

=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  If you do not use the
C<--message> option or the C<--use-default-message> option, then you
will be prompted to enter the message via your text editor.  Use the
C<EDITOR> or C<VISUAL> environment variables to control which editor
is used.  A log message is not required whenever the C<--dry-run>
option is set, or if the action did not yield any changes to the
repository.

=item --pin

Pins the packages to the stack, so they cannot be changed until you
unpin them.  Only the packages in the requested targets will be pinned
-- packages in prerequisites will not be pinned.  However, you may pin
them separately with the L<pin|App::Pinto::Command::pin> command if
you so desire.

=item --stack=NAME

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
