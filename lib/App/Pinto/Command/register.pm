# ABSTRACT: put existing packages on a stack

package App::Pinto::Command::register;

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
        [ 'dry-run'     => 'Do not commit any changes'              ],
        [ 'message|m=s' => 'Message to describe the change'         ],
        [ 'pin'         => 'Pin packages to the stack'              ],
        [ 'stack|s=s'   => 'Remove packages from this stack'        ],
        [ 'use-default-message|M' => 'Use the generated message'    ],
    );
}

#------------------------------------------------------------------------------

sub args_attribute { return 'targets' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------
1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT register [OPTIONS] ARCHIVE ...

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command adds packages to a stack.  The archive which contains
those packages must already exist in the repository.

To add packages from an archive in an upstream repository, use the
L<pull|App::Pinto::Command::pull> command. To add packages from a
local archive, use the L<add|App::Pinto::Command::add> command.

=head1 COMMAND ARGUMENTS

Arguments are the archives you want to register.  Archives are specified
as C<AUTHOR/ARCHIVE_NAME>.  For example:

  SHAKESPEARE/King-Lear-1.2.tar.gz

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --dry-run

Go through all the motions, but do not actually commit any changes to
the repository.  Use this option to see how the command would potentially
impact the stack.

=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  If you do not use the
C<--message> option or the C<--use-default-message> option, then you
will be prompted to enter the message via your text editor.  Use the
C<EDITOR> or C<VISUAL> environment variables to control which editor
is used.  A log message is not required whenever the C<--dry-run>
option is set, or if the action did not yield any changes to the
repository.

=item --stack=NAME

=item -s NAME

Registers the targets on the stack with the given NAME.  Defaults to the
name of whichever stack is currently marked as the default stack.  Use
the L<stacks|App::Pinto::Command::stacks> command to see the stacks in
the repository.

=item --use-default-message

=item -M

Use the default value for the revision history log message.  Pinto
will generate a semi-informative log message just based on the command
and its arguments.  If you set an explicit message with C<--message>,
the C<--use-default-message> option will be silently ignored.

=back

=cut
